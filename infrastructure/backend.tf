terraform {
  backend "s3" {
    bucket = "jumia-challenge-tf-bucket"
    key = "jumia-challenge/terraform.tfstate"
    encrypt = true
    region = "eu-west-2"
    dynamodb_table = "terraform-locks"
  }
}