# ========= StarkNet Makefile =========

SHELL := /bin/bash

.PHONY: help start_dev set_account declare_local deploy_contract mint_nft set_sepolia_account deploy_sepolia_account declare_sepolia deploy_contract_sepolia invoke_string_arg invoke_str_sepolia call_string_arg test

help:
	@echo "StarkNet Makefile Commands:"
	@echo ""
	@echo " 	make start_dev"
	@echo " 	 	Starts starknet-devnet with seed=0."
	@echo ""
	@echo " 	make set_account"
	@echo " 	 	Imports a devnet account using sncast with preconfigured private key and address."
	@echo ""
	@echo " 	make set_sepolia_account"
	@echo " 	 	Creates a new account on the Sepolia testnet using sncast."
	@echo ""
	@echo " 	make deploy_sepolia_account"
	@echo " 	 	Deploys the previously created Sepolia account to the network."
	@echo ""
	@echo " 	make declare_local CONTRACT_NAME=<contract_name>"
	@echo " 	 	Declares a contract on devnet using the given name (from Scarb.toml or compiled artifacts)."
	@echo ""
	@echo " 	make declare_sepolia CONTRACT_NAME=<contract_name>"
	@echo " 	 	Declares a contract on the Sepolia network using the given name."
	@echo ""
	@echo " 	make deploy_contract CLASS_HASH=<class_hash> OWNER='<comma_separated_values>'"
	@echo " 	 	Deploys a contract on devnet with constructor calldata (OWNER)."
	@echo ""
	@echo " 	make deploy_contract_sepolia CLASS_HASH=<class_hash> OWNER='<comma_separated_values>'"
	@echo " 	 	Deploys a contract on Sepolia with constructor calldata (OWNER)."
	@echo ""
	@echo " 	make mint_nft ADDRESS=<contract_address> FUNC=<function_name> IPFS_HASH='"<args>"'"
	@echo " 	 	Mints an NFT on devnet by invoking a function with IPFS hash as argument."
	@echo ""
	@echo " 	make invoke_string_arg ADDRESS=<contract_address> FUNC=<function_name> CALLDATA='<comma_separated_values>'"
	@echo " 	 	Invokes a function on devnet with calldata passed as string (converted to felt252)."
	@echo ""
	@echo " 	make invoke_str_sepolia ADDRESS=<contract_address> FUNC=<function_name> IPFS_HASH='<args>'"
	@echo " 	 	Invokes a function on Sepolia using an IPFS hash as argument."
	@echo ""
	@echo " 	make call_string_arg ADDRESS=<contract_address> FUNC=<function_name>"
	@echo " 	 	Calls a view function and decodes the felt252 result back to string."
	@echo ""
	@echo " 	make test"
	@echo " 	 	Runs the tests using Scarb. Ensure the Scarb.toml has: test = \"snforge test\" under [script] for Foundry testing."
	@echo ""


start_dev:
	starknet-devnet --seed=0

set_account:
	sncast account import \
	--address=0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691 \
	--type=oz \
	--url=http://127.0.0.1:5050 \
	--private-key=0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9 \
	--add-profile=devnet \
	--silent

set_sepolia_account:
	sncast account create --network=sepolia --name=sepolia

deploy_sepolia_account:
	sncast account deploy --network sepolia --name sepolia

declare_local:
	@echo "Declaring $(CONTRACT_NAME)..."
	@sncast --profile=devnet declare --contract-name=$(CONTRACT_NAME) > tmp_declare_output.txt; \
	class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
	timestamp=$$(date +%s); \
	echo "{\"class_hash\": \"$$class_hash\", \"contract_name\": \"$(CONTRACT_NAME)\", \"timestamp\": $$timestamp}" > .last_declared_local.json; \
	echo "Saved class hash: $$class_hash"; \
	rm tmp_declare_output.txt

declare_sepolia:
	@echo "Declaring $(CONTRACT_NAME)..."
	@sncast --account=sepolia declare --contract-name=$(CONTRACT_NAME) --network sepolia > tmp_declare_output.txt; \
	class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
	timestamp=$$(date +%s); \
	echo "{\"class_hash\": \"$$class_hash\", \"contract_name\": \"$(CONTRACT_NAME)\", \"timestamp\": $$timestamp}" > .last_declared_sepolia.json; \
	echo "Saved class hash: $$class_hash"; \
	rm tmp_declare_output.txt

deploy_contract:
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' .last_declared_local.json))
	@output=$$(sncast --profile=devnet deploy \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		--constructor-calldata $(OWNER)) \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	echo "{\"contract_address\": \"$$contract_address\", \"transaction_hash\": \"$$transaction_hash\", \"timestamp\": $$timestamp}" > .last_deployed_local_contract.json; \
	echo "$$output"


deploy_contract_sepolia:
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' .last_declared_sepolia.json))
	@output=$$(sncast --account=sepolia deploy \
		--network sepolia \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		--constructor-calldata $(OWNER)) \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	echo "{\"contract_address\": \"$$contract_address\", \"transaction_hash\": \"$$transaction_hash\", \"timestamp\": $$timestamp}" > .last_deployed_sepolia_contract.json; \
	echo "$$output"

mint_nft:
	$(eval ADDRESS := $(shell jq -r '.contract_address' .last_deployed_local_contract.json))
	sncast --profile=devnet invoke --contract-address=$(ADDRESS) --function=mint_item --arguments $(OWNER),'"$(IPFS_HASH)"'

mint_nft_sepolia:
	$(eval ADDRESS := $(shell jq -r '.contract_address' .last_deployed_sepolia_contract.json))
	sncast --account=sepolia invoke --contract-address=$(ADDRESS) --network=sepolia --function=mint_item --arguments $(OWNER),'"$(IPFS_HASH)"'

test:
	scarb test

