remote_state {
  backend = "s3"
  config = {
    bucket         = "your-tf-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}