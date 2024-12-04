terraform {
  backend "gcs" {
    bucket = "sachinsoni-sb-bucket-test-poc"
    prefix = "terraform/state/gp_vending"
  }
}
