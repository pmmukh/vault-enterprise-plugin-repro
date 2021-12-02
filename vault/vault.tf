terraform {
}

locals {
  plugin_sha256 = trimspace(file("${path.module}/../vault-auth-plugin-example-256sum"))

  plugin = {
    command = "vault-auth-plugin-example"
    sha256  = local.plugin_sha256
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = var.token
}

provider "null" {
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
    token_type         = "default-batch"
  }
}

resource "vault_generic_endpoint" "user" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/user"
  ignore_absent_fields = true
  data_json            = <<EOT
{
  "policies" : ["user"],
  "password" : "password",
  "token_type" : "batch"
}
EOT
}

resource "vault_policy" "user" {
  name = "user"

  policy = <<EOT
path "*" {
  capabilities = ["create","update","read","list","delete","sudo"]
}
EOT
}


resource "vault_mount" "transit" {
  path                      = "transit"
  type                      = "transit"
  description               = "For encryption/decryption"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "test" {
  backend = vault_mount.transit.path
  name    = "test"
  type    = "aes256-gcm96"
}

# resource "vault_generic_endpoint" "enable-replication" {
#   path           = "sys/replication/performance/primary/enable"
#   disable_read   = true
#   disable_delete = true
#   data_json      = <<EOT
# {}
# EOT
# }

resource "vault_generic_endpoint" "vault-auth-plugin-example-register" {
  path           = "sys/plugins/catalog/auth/vault-auth-plugin-example"
  depends_on = [
    vault_auth_backend.userpass,vault_mount.transit,vault_policy.user
  ]
  disable_read   = true
  disable_delete = true
  data_json      = jsonencode(local.plugin)
}

resource "vault_auth_backend" "vault-auth-plugin-example" {
  type = "vault-auth-plugin-example"
  depends_on = [
    vault_generic_endpoint.vault-auth-plugin-example-register
  ]
  tune {
    token_type = "default-batch"
  }
}

resource "vault_audit" "standard" {
  type = "file"

  options = {
    file_path = "/tmp/vault_audit.log"
  }
}
