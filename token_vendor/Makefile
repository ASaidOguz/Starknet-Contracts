.PHONY: help start_dev set_account set_sepolia_account deploy_sepolia_account test test_coverage clear_coverage

# Default target - show help
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "🛠️  Available Makefile targets:"
	@echo ""
	@echo "📋 GENERAL COMMANDS:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(start_dev|set_|test|clear_coverage)"
	@echo ""
	@echo "📋 CONTRACT OPERATIONS:"
	@echo "  For each deployable contract found in src/, the following targets are generated:"
	@echo "    \033[36mdeclare_local_<contract>\033[0m     Declare contract on local devnet"
	@echo "    \033[36mdeclare_sepolia_<contract>\033[0m   Declare contract on Sepolia testnet"
	@echo "    \033[36mdeploy_local_<contract>\033[0m      Deploy contract on local devnet"
	@echo "    \033[36mdeploy_sepolia_<contract>\033[0m    Deploy contract on Sepolia testnet"
	@echo ""
	@echo "📋 AVAILABLE DEPLOYABLE CONTRACTS:"
	@find src -type f -name "*.cairo" -exec grep -l "#\[starknet::contract\]" {} \; | while read file; do \
		contract_name=$$(grep -A 1 "#\[starknet::contract\]" "$$file" | grep -o 'mod [a-zA-Z_][a-zA-Z0-9_]*' | head -n1 | cut -d' ' -f2); \
		if [ -n "$$contract_name" ]; then \
			echo "    • $$contract_name"; \
		fi; \
	done
	@echo ""
	@echo "📋 USAGE EXAMPLES:"
	@echo "  make start_dev                    # Start local devnet"
	@echo "  make set_account                  # Set up devnet account"
	@echo "  make declare_local_<contract>     # Declare a contract locally"
	@echo "  make deploy_local_<contract>      # Deploy a contract locally"
	@echo "  make ARGUMENTS='arg1 arg2' deploy_local_<contract>  # Deploy with constructor args"
	@echo ""
	@echo "📋 DEPLOYMENT WORKFLOW:"
	@echo "  1. make start_dev                 # Start devnet in another terminal"
	@echo "  2. make set_account              # Import devnet account"
	@echo "  3. make declare_local_<contract> # Declare your contract"
	@echo "  4. make deploy_local_<contract>  # Deploy your contract"
	@echo ""

start_dev: ## Start Starknet devnet with seed 0
	starknet-devnet --seed=0

set_account: ## Import devnet account for local development
	sncast account import \
	--address=0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691 \
	--type=oz \
	--url=http://127.0.0.1:5050 \
	--private-key=0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9 \
	--add-profile=devnet \
	--silent

set_sepolia_account: ## Create Sepolia testnet account
	sncast account create --network=sepolia --name=sepolia

deploy_sepolia_account: ## Deploy Sepolia testnet account
	sncast account deploy --network sepolia --name sepolia

# Testing and Coverage
test: ## Run all tests using Scarb
	@echo "Running tests..."
	scarb test

# Coverage Report Generation
PROJECT_NAME := $(shell grep '^name' Scarb.toml | head -n1 | sed 's/name *= *//; s/"//g')
REPORT_DIR ?= coverage_report
REPORTS_BASE ?= /mnt/c/stark-reports/coverage-reports
PROJECT_REPORT_DIR ?= $(REPORTS_BASE)/$(PROJECT_NAME)
WINDOWS_REPORT_DIR = C:\\stark-reports\\coverage-reports\\$(PROJECT_NAME)
CHROME_PATH ?= C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe

test_coverage: ## Generate test coverage report and open in browser
	snforge test --coverage
	genhtml -o $(REPORT_DIR) ./coverage/coverage.lcov
	mkdir -p $(PROJECT_REPORT_DIR)
	cp -r $(REPORT_DIR)/* $(PROJECT_REPORT_DIR)/
	powershell.exe -Command "Start-Process '$(CHROME_PATH)' -ArgumentList '$(WINDOWS_REPORT_DIR)\\index.html'"

clear_coverage: ## Clean coverage data
	cairo-coverage clean

# Declare and Deploy targets for MockSTRKToken

declare_local_MockSTRKToken: ## Declare MockSTRKToken contract on local devnet
	@echo "Declaring MockSTRKToken (local)..."
	@mkdir -p deployments/devnet/local
	@if sncast --profile=devnet declare --contract-name=MockSTRKToken > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "MockSTRKToken" "$$timestamp" > deployments/devnet/local/MockSTRKToken.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/devnet/local/MockSTRKToken.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for MockSTRKToken"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

declare_sepolia_MockSTRKToken: ## Declare MockSTRKToken contract on Sepolia testnet
	@echo "Declaring MockSTRKToken (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if sncast --account=sepolia declare --contract-name=MockSTRKToken --network sepolia > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "MockSTRKToken" "$$timestamp" > deployments/sepolia/sepolia/MockSTRKToken.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/sepolia/sepolia/MockSTRKToken.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for MockSTRKToken"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

deploy_local_MockSTRKToken: ## Deploy MockSTRKToken contract on local devnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying MockSTRKToken (local)..."
	@mkdir -p deployments/devnet/local
	@if [ ! -f "deployments/devnet/local/MockSTRKToken.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_local_MockSTRKToken"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/devnet/local/MockSTRKToken.json))
	@output=$$(sncast --profile=devnet deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "MockSTRKToken" "$$timestamp" > deployments/devnet/local/MockSTRKToken.deployment.json; \
	echo "✅ Deployed MockSTRKToken successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/devnet/local/MockSTRKToken.deployment.json"; \
	echo "$$output"

deploy_sepolia_MockSTRKToken: ## Deploy MockSTRKToken contract on Sepolia testnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying MockSTRKToken (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if [ ! -f "deployments/sepolia/sepolia/MockSTRKToken.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_sepolia_MockSTRKToken"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/sepolia/sepolia/MockSTRKToken.json))
	@output=$$(sncast --account=sepolia deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--network sepolia \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "MockSTRKToken" "$$timestamp" > deployments/sepolia/sepolia/MockSTRKToken.deployment.json; \
	echo "✅ Deployed MockSTRKToken successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/sepolia/sepolia/MockSTRKToken.deployment.json"; \
	echo "$$output"

# Declare and Deploy targets for Vendor

declare_local_Vendor: ## Declare Vendor contract on local devnet
	@echo "Declaring Vendor (local)..."
	@mkdir -p deployments/devnet/local
	@if sncast --profile=devnet declare --contract-name=Vendor > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "Vendor" "$$timestamp" > deployments/devnet/local/Vendor.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/devnet/local/Vendor.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for Vendor"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

declare_sepolia_Vendor: ## Declare Vendor contract on Sepolia testnet
	@echo "Declaring Vendor (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if sncast --account=sepolia declare --contract-name=Vendor --network sepolia > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "Vendor" "$$timestamp" > deployments/sepolia/sepolia/Vendor.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/sepolia/sepolia/Vendor.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for Vendor"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

deploy_local_Vendor: ## Deploy Vendor contract on local devnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying Vendor (local)..."
	@mkdir -p deployments/devnet/local
	@if [ ! -f "deployments/devnet/local/Vendor.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_local_Vendor"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/devnet/local/Vendor.json))
	@output=$$(sncast --profile=devnet deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "Vendor" "$$timestamp" > deployments/devnet/local/Vendor.deployment.json; \
	echo "✅ Deployed Vendor successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/devnet/local/Vendor.deployment.json"; \
	echo "$$output"

deploy_sepolia_Vendor: ## Deploy Vendor contract on Sepolia testnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying Vendor (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if [ ! -f "deployments/sepolia/sepolia/Vendor.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_sepolia_Vendor"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/sepolia/sepolia/Vendor.json))
	@output=$$(sncast --account=sepolia deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--network sepolia \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "Vendor" "$$timestamp" > deployments/sepolia/sepolia/Vendor.deployment.json; \
	echo "✅ Deployed Vendor successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/sepolia/sepolia/Vendor.deployment.json"; \
	echo "$$output"

# Declare and Deploy targets for ProtocolToken

declare_local_ProtocolToken: ## Declare ProtocolToken contract on local devnet
	@echo "Declaring ProtocolToken (local)..."
	@mkdir -p deployments/devnet/local
	@if sncast --profile=devnet declare --contract-name=ProtocolToken > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "ProtocolToken" "$$timestamp" > deployments/devnet/local/ProtocolToken.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/devnet/local/ProtocolToken.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for ProtocolToken"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

declare_sepolia_ProtocolToken: ## Declare ProtocolToken contract on Sepolia testnet
	@echo "Declaring ProtocolToken (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if sncast --account=sepolia declare --contract-name=ProtocolToken --network sepolia > tmp_declare_output.txt 2>&1; then \
		class_hash=$$(grep -o 'class_hash: 0x[0-9a-fA-F]*' tmp_declare_output.txt | cut -d ' ' -f2); \
		if [ -n "$$class_hash" ]; then \
			timestamp=$$(date +%s); \
			printf '{"class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$class_hash" "ProtocolToken" "$$timestamp" > deployments/sepolia/sepolia/ProtocolToken.json; \
			echo "✅ Saved class hash: $$class_hash to deployments/sepolia/sepolia/ProtocolToken.json"; \
		else \
			echo "❌ Failed to extract class hash from output"; \
			cat tmp_declare_output.txt; \
		fi; \
	else \
		echo "❌ Declaration failed for ProtocolToken"; \
		cat tmp_declare_output.txt; \
	fi; \
	rm -f tmp_declare_output.txt

deploy_local_ProtocolToken: ## Deploy ProtocolToken contract on local devnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying ProtocolToken (local)..."
	@mkdir -p deployments/devnet/local
	@if [ ! -f "deployments/devnet/local/ProtocolToken.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_local_ProtocolToken"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/devnet/local/ProtocolToken.json))
	@output=$$(sncast --profile=devnet deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "ProtocolToken" "$$timestamp" > deployments/devnet/local/ProtocolToken.deployment.json; \
	echo "✅ Deployed ProtocolToken successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/devnet/local/ProtocolToken.deployment.json"; \
	echo "$$output"

deploy_sepolia_ProtocolToken: ## Deploy ProtocolToken contract on Sepolia testnet (use ARGUMENTS='arg1 arg2' for constructor args)
	@echo "Deploying ProtocolToken (sepolia)..."
	@mkdir -p deployments/sepolia/sepolia
	@if [ ! -f "deployments/sepolia/sepolia/ProtocolToken.json" ]; then \
		echo "❌ Class hash file not found. Please declare the contract first with: make declare_sepolia_ProtocolToken"; \
		exit 1; \
	fi
	$(eval CLASS_HASH := $(shell jq -r '.class_hash' deployments/sepolia/sepolia/ProtocolToken.json))
	@output=$$(sncast --account=sepolia deploy \
		--arguments $(ARGUMENTS) \
		--class-hash=$(CLASS_HASH) \
		--network sepolia \
		--salt=5 \
		); \
	contract_address=$$(echo "$$output" | grep "contract_address:" | awk '{print $$2}'); \
	transaction_hash=$$(echo "$$output" | grep "transaction_hash:" | awk '{print $$2}'); \
	timestamp=$$(date +%s); \
	printf '{"contract_address": "%s", "transaction_hash": "%s", "class_hash": "%s", "contract_name": "%s", "timestamp": %s}\n' "$$contract_address" "$$transaction_hash" "$(CLASS_HASH)" "ProtocolToken" "$$timestamp" > deployments/sepolia/sepolia/ProtocolToken.deployment.json; \
	echo "✅ Deployed ProtocolToken successfully!"; \
	echo "Contract Address: $$contract_address"; \
	echo "Transaction Hash: $$transaction_hash"; \
	echo "Deployment saved to: deployments/sepolia/sepolia/ProtocolToken.deployment.json"; \
	echo "$$output"
