terraform {
  backend "gcs" {
    bucket = "sachin-sb-backend"
    prefix = "terraform/state/sandbox"
  }
}
