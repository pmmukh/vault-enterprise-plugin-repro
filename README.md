# How to run

My changes on top of the original repro are a bit of a hot mess and some
are unnecessary, but they work, and I'll clean it up later (probably).

Prep Steps ( to load in the custom binary )

1. Run XC_OSARCH=linux/amd64 make premdev on vault-ent local directory (with the branch vault-4494-testing)
2. Do cp ./bin/vault ~/path-to-repo/vault-binary from vault-ent local directory
3. Run docker build -t vault:my-tag . from this repo, to create/update the image used by compose.


1.  Run setup.sh
1.  When it prompts, enter a valid Vault Enterprise license. (the binary has a license baked in, so random paths work here, its not reqd)
1.  When it prompts, run secondary_login_loop.sh.
1.  Press enter to let tune plugin
1.  Observe the login loops no longer succeed, with message "Error writing data to auth/vault-auth-plugin-example/login: context deadline exceeded"
1.  After a couple more minutes, the login loops succeed again.
1. While not required cause setup.sh runs this at the top, if you want you can also do cleanup with cleanup.sh

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

- Using standard Vault docker image (1.9.0+ent)
- Errors don't occur on the primary node, or if namespaces are not used
