#####################
## Provider - Main ##
#####################

terraform {
  required_version = ">= 0.12"
  backend "gcs" {
     bucket="timo-terraform"
     credentials = "cegeka-gcp-awareness-839303fe82df.json"
  }
}

provider "google" {
  credentials = file("cegeka-gcp-awareness-839303fe82df.json")
  project = var.gcp_project
  region  = var.gcp_region
}
