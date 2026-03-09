# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "eks-project-homelab-backend-bucket004"
    key     = "vpc-terraform-github-action.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}