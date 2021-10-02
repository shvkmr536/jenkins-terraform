provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "ecsworkshopbucket536"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key = "LockID"
  name     = "terraform-test-locks"
  billing_mode = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
attribute {
  name = "LockID"
  type = "S"
}
}

/*terraform {
  backend "s3"{
    #bucket details
    bucket = "ecsworkshopbucket536"
    region = "us-east-1"
    key = "myapp/prod/terraform.tfstate"
    # DynamoDB table name
    dynamodb_table = "terraform-test-locks"
    encrypt = true
  }
}
*/
