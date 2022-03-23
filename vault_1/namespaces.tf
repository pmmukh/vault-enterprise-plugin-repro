provider "vault" {
  address   = "http://127.0.0.1:8200"
  namespace = "ns1"
  alias     = "ns1"
  token     = var.token
}

provider "vault" {
  address   = "http://127.0.0.1:8200"
  namespace = "ns2"
  alias     = "ns2"
  token     = var.token
}

resource "vault_namespace" "namespace_ns1" {
  path = "ns1"
}

resource "vault_auth_backend" "vault-auth-plugin-example_ns1" {
  provider = vault.ns1
  type     = "vault-auth-plugin-example"
  depends_on = [
    vault_namespace.namespace_ns1,vault_generic_endpoint.vault-auth-plugin-example-register
  ]
  tune {
    token_type = "default-batch"
  }
}

resource "vault_namespace" "namespace_ns2" {
  path = "ns2"
}

resource "vault_auth_backend" "vault-auth-plugin-example_ns2" {
  provider = vault.ns2
  type     = "vault-auth-plugin-example"
  depends_on = [
    vault_namespace.namespace_ns2,vault_generic_endpoint.vault-auth-plugin-example-register
  ]
  tune {
    token_type = "default-batch"
  }
}