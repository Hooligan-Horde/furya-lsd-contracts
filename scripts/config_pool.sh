#!/usr/bin/env bash

config_pool() {
  echo "-------------------------- config pool -------------------------------------"

  msg=$(printf '{
  "config_pool": {
    "pool_addr": "%s",
    "lsm_support": true,
    "offset": 6
  }
}' "$pool_address")
  # echo "config pool msg is: $msg"
  tx_result="$(neutrond tx wasm execute "$contract_address" "$msg" \
    --from "$ADDRESS_1" -y --chain-id "$CHAIN_ID_1" --output json \
    --broadcast-mode=sync --gas-prices 0.0025untrn --gas 1000000 \
    --keyring-backend=test --home "$HOME_1" --node "$NEUTRON_NODE" | wait_tx)"

  code="$(echo "$tx_result" | jq '.code')"
  if [[ "$code" -ne 0 ]]; then
    echo "Failed to config pool: $(echo "$tx_result" | jq '.raw_log')" && exit 1
  fi

  query="$(printf '{"pool_info": {"pool_addr": "%s"}}' "$pool_address")"
  echo "------------------------ pool_info after config ------------------------"
  neutrond query wasm contract-state smart "$contract_address" "$query" --node "$NEUTRON_NODE" --output json | jq

  echo "------------------------ DelegatorWithdrawAddress Query -----------------------------------"
  grpcurl -plaintext -d "{\"delegator_address\":\"$pool_address\"}" localhost:9090 cosmos.distribution.v1beta1.Query/DelegatorWithdrawAddress | jq

  echo "------------------------ Config Pool To Trust list -----------------------------------"
  msg=$(printf '{
    "config_stack": {
      "add_entrusted_pool": "%s"
    }
  }' "$pool_address")

  tx_result="$(neutrond tx wasm execute "$contract_address" "$msg" \
    --from "$ADDRESS_1" -y --chain-id "$CHAIN_ID_1" --output json \
    --broadcast-mode=sync --gas-prices 0.0025untrn --gas 1000000 \
    --keyring-backend=test --home "$HOME_1" --node "$NEUTRON_NODE" | wait_tx)"

  code="$(echo "$tx_result" | jq '.code')"
  if [[ "$code" -ne 0 ]]; then
    echo "Failed to config pool: $(echo "$tx_result" | jq '.raw_log')" && exit 1
  fi
}
