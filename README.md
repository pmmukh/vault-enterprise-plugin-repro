# How to run

1.  Run setup.sh
1.  When it prompts, run secondary_login_loop.sh, secondary_login_loop_1.sh, secondary_login_loop_2.sh
1.  Press enter to let tune plugin
1.  Observe the login loops no longer succeed, with message "Error writing data to auth/vault-auth-plugin-example/login: context deadline exceeded"
1.  After a couple more minutes, the login loops succeed again.

# Notes on setup

- Docker-compose creates
- a "auto-unseal" vault (1 instance running in memory storage)
- 2 Vault clusters using Consul storage.   Each cluster has 3 instances that write to a single consul backend.   (vault_1, vault_2, vault_3 --> consul_1) (vault2_1, vault2_2, vault_3 --> consul_2)
- Each vault instance has the vault auth plugin sample "https://github.com/hashicorp/vault-auth-plugin-example".
- We setup vault performance replication (primary is vault_1, vault_2, vault_3,  performance secondary is vault2_1, vault2_2, vault2_3)
- Through terraform, we configure vault, it has 3 namespace, (root, ns1, ns2).  All namespace has vault-auth-plugin-example enabled
- secondary_login_loop_\*.sh is endless loop to login into the plugin on the different performance secondary cluster instances on the different namespaces

- finally, setup.sh will tune the plugin mount's audit-non-hmac-response-keys, which causes the secondary_login_loops to fail (temporarily)

# Other notes

- Using standard Vault docker image (1.5.7+ent)
- The vault-plugin sha256 can be found in step 14 of docker-compose build .
