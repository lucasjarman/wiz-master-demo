terraform {
  required_version = ">= 1.5.0"
  required_providers {
    wiz = {
      version = "~> 1.8"
      source  = "tf.app.wiz.io/wizsec/wiz"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}
