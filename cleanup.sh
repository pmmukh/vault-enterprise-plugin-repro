#!/bin/bash


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