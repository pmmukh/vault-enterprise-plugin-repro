#!/bin/bash

docker-compose stop
pushd ./transit-vault
rm -rf .terraform/
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

pushd ./vault
rm -rf .terraform/
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

pushd ./vault_2
rm -rf .terraform/
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
popd

echo "Start docker-compose on vault_transit"

docker-compose up --no-start
docker-compose start vault_transit
pushd ./transit-vault
terraform init
terraform apply -auto-approve
popd

echo "Start docker-compose on vault cluster 1"
docker-compose start statsd
docker-compose start consul
docker-compose start vault_1
docker-compose start vault_2
docker-compose start vault_3
RESPONSE=$(
    vault operator init -address=http://127.0.0.1:8200 -recovery-shares=1 -recovery-threshold=1 -format=json)
echo $RESPONSE
ROOT_TOKEN_1=$(echo $RESPONSE | jq -j .root_token)
echo ROOT_TOKEN_1 = $ROOT_TOKEN_1
pushd ./vault
VAULT_TOKEN=$ROOT_TOKEN_1 terraform init
VAULT_TOKEN=$ROOT_TOKEN_1 terraform apply -auto-approve
popd
#vault login -address=http://127.0.0.1:8200 -method=userpass username=user password=password
echo "Setup done"


echo "Start docker-compose on vault cluster 2"
docker-compose start consul2
docker-compose start vault2_1
docker-compose start vault2_2
docker-compose start vault2_3
RESPONSE=$(vault operator init -address=http://127.0.0.1:8300 -recovery-shares=1 -recovery-threshold=1 -format=json)
echo $RESPONSE
ROOT_TOKEN_2=$(echo $RESPONSE | jq -j .root_token)
echo ROOT_TOKEN_2 = $ROOT_TOKEN_2
pushd ./vault_2
VAULT_TOKEN=$ROOT_TOKEN_2 terraform init
VAULT_TOKEN=$ROOT_TOKEN_2 terraform apply -auto-approve
popd
echo "Setup done"

sleep 5
#docker-compose logs -f
echo "Setup performance replication"
echo ROOT_TOKEN_1 $ROOT_TOKEN_1
echo ROOT_TOKEN_2 $ROOT_TOKEN_2

REPLICATION_TOKEN=$(VAULT_TOKEN=$ROOT_TOKEN_1 vault write -address=http://127.0.0.1:8200 -format=json sys/replication/performance/primary/secondary-token id=secondary | jq -r ".wrap_info.token")
echo REPLICATION_TOKEN $REPLICATION_TOKEN

VAULT_TOKEN=$ROOT_TOKEN_2 vault write -address=http://127.0.0.1:8300 sys/replication/performance/secondary/enable token=$REPLICATION_TOKEN
sleep 10
docker-compose restart vault2_2
docker-compose restart vault2_3

CLUSTER2_TOKEN=$(vault write -address=http://127.0.0.1:8300 -format=json auth/userpass/login/user password=password | jq -r ".auth.client_token")
echo CLUSTER2_TOKEN $CLUSTER2_TOKEN
echo "Setup done"

echo "In seperate terminal windows, launch secondary_login_loop_1.sh, secondary_login_loop_2.sh, secondary_login_loop_3.sh, primary_login_loop.sh"
echo "You may also want to tail server logs by running docker-compose logs -f."
echo "When that is done,"
read -p "Press enter to tune the audit_non_hmac_response_keys for vault-auth-plugin-example plugin in namespaces"

VAULT_TOKEN=$ROOT_TOKEN_1 vault auth tune -address=http://127.0.0.1:8200 -namespace=ns1 -audit-non-hmac-response-keys=error2 vault-auth-plugin-example/
VAULT_TOKEN=$ROOT_TOKEN_1 vault auth tune -address=http://127.0.0.1:8200 -namespace=ns2 -audit-non-hmac-response-keys=error2 vault-auth-plugin-example/
VAULT_TOKEN=$ROOT_TOKEN_1 vault auth tune -address=http://127.0.0.1:8200 -audit-non-hmac-response-keys=error2 vault-auth-plugin-example/
