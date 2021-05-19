#!/bin/bash

export VAULT_CLIENT_TIMEOUT=1s
while :
do
    vault write -address=http://127.0.0.1:8300 -format=json auth/vault-auth-plugin-example/login password=super-secret-password
    sleep 0.1
done
