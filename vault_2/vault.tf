terraform {
}

provider "vault" {
  address = "http://127.0.0.1:8300"
  token   = var.token
}
