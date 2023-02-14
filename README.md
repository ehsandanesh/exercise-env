# Exercise app
This repository contains the Trraform manifests to bring up the whole environment for the purpose of this exercise  

# Different components
Different components that is manage by this Terraform code are:  
- VPC
- EKS
- ECR and its policy
- github runner controller CRD and its runner
- EKS ingress controller 

## Modules and resources
- EKS
- aws
- ECR
- helm
- kubectl

# Permission
This Terraform ran by aws admin user to simplify the process and that admin user is being used in other places like pipeline and ECR.

# How to deploy
terraform init
terraform plan
terraform apply
terraform output

# Hoe to destroy
terraform destroy
# Outputs
After running the terraform apply or terraform output all the necessary information for pipeline except credentials will be printed out like:  
available_zones = tolist([  
  "us-east-1a",  
  "us-east-1b",  
  "us-east-1c",  
])  
cluster_endpoint = "https://EDA331C9FBD03CBA82953FCDF9BC5110.gr7.us-east-1.eks.amazonaws.com"  
cluster_name = "exercise"  
cluster_security_group_id = "sg-06cb24f2d2495d5b2"  
ecr_url = "943643145581.dkr.ecr.us-east-1.amazonaws.com/exercise-app"  
exercise_access_key_id = "AKIA5XNMDWVWRDQDRTN5"  
region = "us-east-1"  


