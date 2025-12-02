terraform {
  backend "s3" {
    bucket         = "devops-stage-6-tf-state-1764688200"
    key            = "devops-app/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}