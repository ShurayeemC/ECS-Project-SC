terraform {
  backend "s3" {
    bucket         = "sc-terraform-statee"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sc-terraform-state-lock"
    encrypt        = true
  }
}