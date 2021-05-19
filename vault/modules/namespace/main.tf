# Every Vault resource needs to reference a provider
# To prevent creation/deletion of the root namespace
provider "vault" {
  alias = "namespace"
}

provider "vault" {
  alias = "root"
}

provider "null" {
}

# This is to express that the zone namespace is dependent on the root module's utoken plugin being registered
# https://medium.com/@aniket10051994/inter-module-resource-dependency-in-terraform-9291070133f3
resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
    command = "echo ${join(",", var.dependencies)}"
  }
}

resource "vault_namespace" "namespace" {
  provider   = vault.root
  depends_on = [null_resource.dependency_getter]
  path       = var.namespace
}

resource "vault_auth_backend" "vault-auth-plugin-example" {
  provider = vault.namespace
  type     = "vault-auth-plugin-example"
  depends_on = [
    vault_namespace.namespace
  ]
  tune {
    token_type = "default-batch"
  }
}
