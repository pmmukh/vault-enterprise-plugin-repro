#!/bin/bash

while :
do
    vault write -address=http://127.0.0.1:8298 -format=json auth/vault-auth-plugin-example/login password=super-secret-password
    sleep 0.1
done
