output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "available_zones" {
  description = "Available zones in this region"
  value = slice(data.aws_availability_zones.available.names, 0, 3)
}


output "ecr_url" {
    description = "this is ECR url"
    value = aws_ecr_repository.exercise.repository_url 
}


output "exercise_access_key_token" {
  value = aws_iam_access_key.exercise_access_key.encrypted_secret
}

output "exercise_access_key_id" {
  value = aws_iam_access_key.exercise_access_key.id
}
#output "kube_cert" {
#  description = "Available zones in this region"
#  value = data.aws_eks_cluster.cluster.certificate_authority[0].data
#}
