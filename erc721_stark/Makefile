# ========= StarkNet Makefile =========

SHELL := /bin/bash

.PHONY: help start_dev set_account declare_local deploy_contract mint_nft set_sepolia_account deploy_sepolia_account declare_sepolia deploy_contract_sepolia invoke_string_arg invoke_str_sepolia call_string_arg test

help:
	@echo ""
	@echo "StarkNet Makefile Commands:"
	@echo "============================"
	@echo ""
	@echo "🔧 Devnet:"
	@echo "  make start_dev                          - Start starknet-devnet with seed=0"
	@echo "  make set_account                        - Import a predefined devnet account into sncast"
	@echo ""
	@echo "🌐 Sepolia:"
	@echo "  make set_sepolia_account                - Create a new Sepolia testnet account"
	@echo "  make deploy_sepolia_account            - Deploy the Sepolia account to the network"
	@echo ""
	@echo "📦 Contract Declaration:"
	@echo "  make declare_local CONTRACT_NAME=name   - Declare a contract locally on devnet"
	@echo "  make declare_sepolia CONTRACT_NAME=name - Declare a contract on Sepolia"
	@echo ""
	@echo "🚀 Contract Deployment:"
	@echo "  make deploy_contract OWNER='args'       - Deploy locally with constructor calldata"
	@echo "  make deploy_contract_sepolia OWNER='args' - Deploy to Sepolia with constructor calldata"
	@echo ""
	@echo "🖼️  NFT Minting:"
	@echo "  make mint_nft OWNER=addr IPFS_HASH=hash_value      - Mint NFT on devnet"
	@echo "  make mint_nft_sepolia OWNER=addr IPFS_HASH=hash_value - Mint NFT on Sepolia"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  make test                               - Run tests using Scarb"
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
		--arguments $(OWNER),'"$(NAME)"'\
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		) \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	echo "{\"contract_address\": \"$$contract_address\", \"transaction_hash\": \"$$transaction_hash\", \"timestamp\": $$timestamp}" > .last_deployed_local_contract.json; \
	echo "$$output"


deploy_contract_sepolia:
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' .last_declared_sepolia.json))
	@output=$$(sncast --account=sepolia deploy \
		--arguments $(OWNER),'"$(NAME)"' \
		--network sepolia \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		) \
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
	
# Coverage Report Generation
PROJECT_NAME ?= erc721_stark
REPORT_DIR = coverage_report
REPORTS_BASE = /mnt/c/stark-reports/coverage-reports
PROJECT_REPORT_DIR = $(REPORTS_BASE)/$(PROJECT_NAME)

WINDOWS_REPORT_DIR = C:\\stark-reports\\coverage-reports\\$(PROJECT_NAME)
CHROME_PATH ?= C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe

test_coverage:
	snforge test --coverage
	genhtml -o $(REPORT_DIR) ./coverage/coverage.lcov
	mkdir -p $(PROJECT_REPORT_DIR)
	cp -r $(REPORT_DIR)/* $(PROJECT_REPORT_DIR)/
	powershell.exe -Command "Start-Process '$(CHROME_PATH)' -ArgumentList '$(WINDOWS_REPORT_DIR)\\index.html'"

coverage_clean:
	cairo-coverage clean

