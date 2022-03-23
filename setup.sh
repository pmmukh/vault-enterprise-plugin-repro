#!/bin/bash

echo 'enter vault license path'
read VAULT_LICENSE_PATH
export VAULT_LICENSE=$(cat $VAULT_LICENSE_PATH)

echo ""
echo "Cleanup env vars"
echo ""
rm -rf ~/.vault-token
export VAULT_ADDR=
export VAULT_NAMESPACE=
echo ""
echo "done"
echo ""

echo ""
echo "Clean up previous runs"
echo ""

docker compose down
pushd ./transit-vault
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

pushd ./vault_1
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

pushd ./vault_2
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

echo ""
echo "done"
echo ""

echo "sync and build plugin as submodule"
git submodule update

pushd ./vault-auth-plugin-example 
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -tags netgo -ldflags '-w' -o vault-auth-plugin-example *.go
popd

shasum -a 256 ./vault-auth-plugin-example/vault-auth-plugin-example | cut -d " " -f1 > vault-auth-plugin-example-256sum

echo ""
echo "done"
echo ""

echo ""
echo "Start docker-compose on vault_transit"
echo ""

docker compose up --no-start
docker compose start vault_transit
lsof -i :8202
sleep 10s
lsof -i :8202

pushd ./transit-vault
terraform init
terraform apply -auto-approve
popd

echo ""
echo "done"
echo ""

echo ""
echo "Start docker-compose on vault cluster 1"
echo ""

docker compose start statsd
docker compose start consul
docker compose start vault_1
sleep 5s
RESPONSE=$(
    vault operator init -address=http://127.0.0.1:8200 -recovery-shares=1 -recovery-threshold=1 -format=json)
echo $RESPONSE
ROOT_TOKEN_1=$(echo $RESPONSE | jq -j .root_token)
echo ROOT_TOKEN_1 = $ROOT_TOKEN_1
pushd ./vault_1
terraform init -var="token=$ROOT_TOKEN_1"
terraform apply -auto-approve -var="token=$ROOT_TOKEN_1" -parallelism=1
popd
#vault login -address=http://127.0.0.1:8200 -method=userpass username=user password=password
echo ""
echo "Setup done"
echo ""

echo ""
echo "Start docker-compose on vault cluster 2"
echo ""

docker compose start consul2
docker compose start vault2_1
sleep 5s

RESPONSE=$(vault operator init -address=http://127.0.0.1:8300 -recovery-shares=1 -recovery-threshold=1 -format=json)
echo $RESPONSE
ROOT_TOKEN_2=$(echo $RESPONSE | jq -j .root_token)
echo ROOT_TOKEN_2 = $ROOT_TOKEN_2
pushd ./vault_2
terraform init -var="token=$ROOT_TOKEN_2"
terraform apply -auto-approve -var="token=$ROOT_TOKEN_2"
popd
echo ""
echo "Setup done"
echo ""

sleep 5
#docker-compose logs -f
echo ""
echo "Setup performance replication"
echo ""
echo ROOT_TOKEN_1 $ROOT_TOKEN_1
echo ROOT_TOKEN_2 $ROOT_TOKEN_2

VAULT_TOKEN=$ROOT_TOKEN_1 vault write -address=http://127.0.0.1:8200 -force sys/replication/performance/primary/enable
sleep 10
REPLICATION_TOKEN=$(VAULT_TOKEN=$ROOT_TOKEN_1 vault write -address=http://127.0.0.1:8200 -format=json sys/replication/performance/primary/secondary-token id=secondary | jq -r ".wrap_info.token")
echo REPLICATION_TOKEN $REPLICATION_TOKEN

VAULT_TOKEN=$ROOT_TOKEN_2 vault write -address=http://127.0.0.1:8300 sys/replication/performance/secondary/enable token=$REPLICATION_TOKEN
sleep 10
docker compose restart vault2_1
sleep 20s

echo ""
echo "done"
echo ""

echo ""
echo "test replication is working"
echo ""
CLUSTER2_TOKEN=$(vault write -address=http://127.0.0.1:8300 -format=json auth/userpass/login/user password=password | jq -r ".auth.client_token")
echo CLUSTER2_TOKEN $CLUSTER2_TOKEN
echo ""
echo "Setup done"
echo ""

echo "In seperate terminal windows, launch secondary_login_loop_1.sh, secondary_login_loop_2.sh, secondary_login_loop_3.sh, primary_login_loop.sh"
echo "You may also want to tail server logs by running docker-compose logs -f."
echo "When that is done,"
read -p "Press enter to tune the audit_non_hmac_response_keys for vault-auth-plugin-example plugin in namespaces"

VAULT_TOKEN=$ROOT_TOKEN_1 vault auth tune -address=http://127.0.0.1:8200 -namespace=ns1 -audit-non-hmac-response-keys=error3 vault-auth-plugin-example/
VAULT_TOKEN=$ROOT_TOKEN_1 vault auth tune -address=http://127.0.0.1:8200 -audit-non-hmac-response-keys=error3 vault-auth-plugin-example/

echo $(date -u) "Done tuning"
