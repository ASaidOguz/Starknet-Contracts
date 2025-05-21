# ========= StarkNet Makefile =========

SHELL := /bin/bash

.PHONY: help start_dev set_account declare_local deploy_contract mint_nft set_sepolia_account deploy_sepolia_account declare_sepolia deploy_contract_sepolia invoke_string_arg invoke_str_sepolia call_string_arg test

help:
	@echo ""
	@echo "========= StarkNet Makefile Commands ========="
	@echo ""
	@echo "🧪 Local Dev Commands"   
	@echo "  make start_dev                                                                    # Start local devnet with fixed seed"
	@echo "  make set_account                                                                  # Import predefined devnet account"
	@echo "  make declare_local CONTRACT_NAME=<name>                                           # Declare a local contract"
	@echo "  make deploy_contract AMOUNT_LOW=<low> AMOUNT_HIGH=<high> OWNER=<address>          # Deploy locally"
	@echo "  make mint_local RECIPIENT=<address> AMOUNT_LOW=<low> AMOUNT_HIGH=<high>           # Mint tokens locally"
	@echo ""
	@echo "🌍 Sepolia Testnet Commands"
	@echo "  make set_sepolia_account                                                          # Create new Sepolia account"
	@echo "  make deploy_sepolia_account                                                       # Deploy Sepolia account to network"
	@echo "  make declare_sepolia CONTRACT_NAME=<name>                                         # Declare a contract on Sepolia"
	@echo "  make deploy_contract_sepolia AMOUNT_LOW=<low> AMOUNT_HIGH=<high> OWNER=<address>  # Deploy to Sepolia"
	@echo ""
	@echo "📌 Example:"
	@echo "  make declare_local CONTRACT_NAME=MyERC20"
	@echo "  make deploy_contract AMOUNT_LOW=1000 AMOUNT_HIGH=0 OWNER=0x123..."
	@echo "  make mint_local RECIPIENT=0xabc... AMOUNT_LOW=500 AMOUNT_HIGH=0"
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
ifndef AMOUNT_LOW
	$(error AMOUNT_LOW not set)
endif
ifndef AMOUNT_HIGH
	$(error AMOUNT_HIGH not set)
endif
ifndef OWNER
	$(error OWNER not set)
endif
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' .last_declared_local.json))
	@echo "Deploying contract with class hash $(CLASS_HASH)..."
	@output=$$(sncast --profile=devnet deploy \
		--class-hash=$(CLASS_HASH) \
		--salt=0 \
		--constructor-calldata $(AMOUNT_LOW) $(AMOUNT_HIGH) $(OWNER)); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	echo "{\"contract_address\": \"$$contract_address\", \"transaction_hash\": \"$$transaction_hash\", \"timestamp\": $$timestamp}" > .last_deployed_local_contract.json; \
	echo "$$output"
	
deploy_contract_sepolia:
ifndef AMOUNT_LOW
	$(error AMOUNT_LOW not set)
endif
ifndef AMOUNT_HIGH
	$(error AMOUNT_HIGH not set)
endif
ifndef OWNER
	$(error OWNER not set)
endif
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' .last_declared_sepolia.json))
	@echo "Deploying contract with class hash $(CLASS_HASH)..."
	@output=$$(sncast --account=sepolia deploy \
		--class-hash=$(CLASS_HASH) \
		--network=sepolia \
		--salt=1 \
		--constructor-calldata $(AMOUNT_LOW) $(AMOUNT_HIGH) $(OWNER)); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	echo "{\"contract_address\": \"$$contract_address\", \"transaction_hash\": \"$$transaction_hash\", \"timestamp\": $$timestamp}" > .last_deployed_sepolia_contract.json; \
	echo "$$output"


mint_local:
ifndef RECIPIENT
	$(error RECIPIENT not set)
endif
ifndef AMOUNT_LOW
	$(error AMOUNT_LOW not set)
endif
ifndef AMOUNT_HIGH
	$(error AMOUNT_HIGH not set)
endif
	$(eval ADDRESS := $(shell jq -r '.contract_address' .last_deployed_local_contract.json))
	@echo "Minting to $(RECIPIENT) amount: $(AMOUNT_LOW) $(AMOUNT_HIGH)..."
	@sncast --profile=devnet invoke \
		--contract-address=$(ADDRESS) \
		--function=mint \
		--calldata $(RECIPIENT) $(AMOUNT_LOW) $(AMOUNT_HIGH)
