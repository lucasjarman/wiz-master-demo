terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
    region       = "ap-southeast-2"
  }
}
