# Domain Controller Infrastructure-as-Code Makefile
# Simple project for school - Free Tier optimized

.PHONY: help init plan deploy destroy clean check-tools

# Default target
.DEFAULT_GOAL := help

# Simplified paths (no environment management)
TF_DIR := .cloud/terraform
PACKER_DIR := .cloud/packer
ANSIBLE_DIR := .cloud/ansible
CONFIG_DIR := .config

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

## Display this help message
help:
	@echo "$(BLUE)Domain Controller IAC - School Project$(RESET)"
	@echo "$(YELLOW)Free Tier Optimized - Cost: ~0.50€/month$(RESET)"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET)"
	@echo "  make [target]"
	@echo ""
	@echo "$(GREEN)Main Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"}; /^[a-zA-Z_-]+:.*##/ { printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Workflow:$(RESET)"
	@echo "  1. make init     # Initialize project"
	@echo "  2. make plan     # Preview changes"
	@echo "  3. make deploy   # Deploy infrastructure"
	@echo "  4. make destroy  # Clean up"

## Initialize the project
init: check-tools
	@echo "$(GREEN)🚀 Initializing project...$(RESET)"
	@echo "$(YELLOW)📦 Setting up Terraform...$(RESET)"
	cd $(TF_DIR) && terraform init
	@echo "$(GREEN)✅ Project initialized!$(RESET)"

## Plan infrastructure changes
plan: check-tools
	@echo "$(YELLOW)📋 Planning infrastructure changes...$(RESET)"
	cd $(TF_DIR) && terraform plan -var-file="../$(CONFIG_DIR)/variables/terraform.tfvars"
	@echo "$(GREEN)✅ Plan completed!$(RESET)"

## Deploy infrastructure (Terraform only)
deploy: check-tools
	@echo "$(GREEN)🚀 Deploying infrastructure...$(RESET)"
	@echo "$(YELLOW)🏗️  Deploying with Terraform...$(RESET)"
	cd $(TF_DIR) && terraform apply -var-file="../$(CONFIG_DIR)/variables/terraform.tfvars" -auto-approve
	@echo "$(GREEN)✅ Infrastructure deployed!$(RESET)"
	@echo "$(BLUE)📋 Connection Info:$(RESET)"
	@cd $(TF_DIR) && terraform output

## Destroy all infrastructure
destroy: check-tools
	@echo "$(RED)💥 WARNING: This will destroy ALL infrastructure!$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "$(YELLOW)🗑️  Destroying infrastructure...$(RESET)"
	cd $(TF_DIR) && terraform destroy -var-file="../$(CONFIG_DIR)/variables/terraform.tfvars" -auto-approve
	@echo "$(RED)✅ Infrastructure destroyed!$(RESET)"

## Clean temporary files
clean:
	@echo "$(YELLOW)🧹 Cleaning temporary files...$(RESET)"
	find . -name "*.tfstate.backup" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "packer_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed!$(RESET)"

## Validate configurations
validate: check-tools
	@echo "$(YELLOW)🔍 Validating Terraform...$(RESET)"
	cd $(TF_DIR) && terraform validate
	@echo "$(GREEN)✅ Configuration valid!$(RESET)"

## Show infrastructure status
status: check-tools
	@echo "$(BLUE)📊 Infrastructure Status:$(RESET)"
	@cd $(TF_DIR) && terraform show 2>/dev/null || echo "  No infrastructure deployed"

## Check required tools
check-tools:
	@echo "$(YELLOW)🔧 Checking tools...$(RESET)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)❌ Terraform not installed$(RESET)"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "$(RED)❌ AWS CLI not installed$(RESET)"; exit 1; }
	@echo "$(GREEN)✅ All tools available$(RESET)" 