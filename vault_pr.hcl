storage "consul" {
  address = "consul2:8500"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

telemetry = {
  statsd_address = "statsd:8125"
}

seal "transit" {
  address = "http://vault_transit:8200"
  disable_renewal = "false"
  key_name = "auto-unseal"
  mount_path = "transit"
  tls_skip_verify = "false"
  token = "root"
}

log_level = "Debug"
plugin_directory = "/usr/local/bin/vault/"
disable_mlock = true