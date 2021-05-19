terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  required_version = ">= 0.13"
}
