terraform {
  backend "s3" {
    bucket       = "demo-dev-c1dfca-state-bucket-ap-southeast-2"
    key          = "infrastructure/demo/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
