terraform {
  backend "gcs" {
    bucket = "sachinsoni-sb-bucket-test-poc"
    prefix = "terraform/state/sandbox_vending"
  }
}
