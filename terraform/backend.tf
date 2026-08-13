terraform {
  backend "s3" {
    encrypt      = true
    region       = "eu-central-1"
    use_lockfile = true
  }
}
