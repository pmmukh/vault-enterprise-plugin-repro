provider "vault" {
  address   = "http://127.0.0.1:8200"
  namespace = "ns1"
  alias     = "ns1"
}

module "ns1" {
  source       = "./modules/namespace/"
  namespace    = "ns1"
  dependencies = [vault_generic_endpoint.vault-auth-plugin-example-register.id]
  providers = {
    vault.namespace = vault.ns1
    vault.root      = vault
    null            = null
  }
}

provider "vault" {
  address   = "http://127.0.0.1:8200"
  namespace = "ns2"
  alias     = "ns2"
}

module "ns2" {
  source       = "./modules/namespace/"
  namespace    = "ns2"
  dependencies = [vault_generic_endpoint.vault-auth-plugin-example-register.id]
  providers = {
    vault.namespace = vault.ns2
    vault.root      = vault
    null            = null
  }
}
