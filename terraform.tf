terraform {
  required_version = ">= 1.9"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.72"
    }
  }
}
