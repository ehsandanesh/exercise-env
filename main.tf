provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "exercise"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  tags = {
    Terraform = "true"
    Environment = var.cluster_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.7.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
#  manage_aws_auth_configmap = true

  eks_managed_node_group_defaults = {
    instance_types = ["t2.small", "t2.medium", "t2.large"]
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

  }




#  node_security_group_additional_rules = {
#    ingress_allow_access_from_control_plane = {
#      type                          = "ingress"
#      protocol                      = "tcp"
##      from_port                     = 9443
##      to_port                       = 9443
#      source_cluster_security_group = true
#      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
#    }
#  }
#


}




resource "aws_ecr_repository" "exercise" {
  name                 = "exercise-app"
  image_tag_mutability = "MUTABLE"
  force_delete = true
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

resource "aws_ecr_repository_policy" "exercise" {
  repository = aws_ecr_repository.exercise.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Exercise policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user" "exercise" {
  name = "exercise"
  path = "/test/"
}

resource "aws_iam_access_key" "exercise_access_key" {
  user = aws_iam_user.exercise.name
}




#data "aws_eks_cluster" "cluster" {
#  name = module.eks.cluster_name
#}
#
#data "aws_eks_cluster_auth" "cluster" {
#  name = module.eks.cluster_arn
#}
#
#
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = ["eks", "get-token", "--cluster-name",var.cluster_name]
    command = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args = ["eks", "get-token", "--cluster-name",var.cluster_name]
      command = "aws"
    }
  }
}


resource "helm_release" "github_action_cert_manager" {
  name       = "github-action-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  create_namespace = true
  namespace = "cert-manager"
  version = "v1.3.0"
  set {
    name = "installCRDs"
    value = true

  }
  depends_on = [ module.eks ]
}

resource "helm_release" "github_action_controller" {
  name       = "github-action-controller"
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  namespace = "cert-manager"
  set {
    name = "authSecret.create"
    value = true

  }
  set_sensitive {
    name  = "authSecret.github_token"
    value = var.github_token
  }
  depends_on = [ helm_release.github_action_cert_manager ]
}


data "template_file" "yaml_template" {
  template = file("${path.module}/github-runner.yaml")
  vars = {
    repo_address = var.repo_address
  }
}

resource "kubectl_manifest" "github_runner_crd" {
  #yaml_body = yamldecode(data.template_file.yaml_template.rendered)
  yaml_body = data.template_file.yaml_template.rendered
  depends_on = [ helm_release.github_action_controller, module.eks , helm_release.github_action_cert_manager ]
}

data "template_file" "yaml_template_app" {
  template = file("${path.module}/github-runner-app.yaml")
  vars = {
    repo_address = var.repo_address_app
  }
}


resource "kubectl_manifest" "github_runner_crd_app" {
  count = var.app_runner_enabled == true ? 1 : 0
  yaml_body = data.template_file.yaml_template_app.rendered
  depends_on = [ helm_release.github_action_controller, module.eks , helm_release.github_action_cert_manager ]
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "autoDiscoverAwsRegion"
    value = true
  }

  set {
    name  = "autoDiscoverAwsVpcID"
    value = true
  }



  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}


resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy"
  description = "Worker policy for the ALB Ingress"

  policy = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.worker_policy.arn
  role       = each.value.iam_role_name
}
