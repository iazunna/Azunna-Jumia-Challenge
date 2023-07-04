terraform {
  backend "s3" {
    bucket = "jumia-challenge-tf-bucket"
    key = "jumia-challenge/terraform.tfstate"
    encrypt = true
    region = local.region
    dynamodb_table = "terraform-locks"
  }
}