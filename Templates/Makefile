.PHONY: init plan apply destroy validate fmt help

help:
	@echo "Kubernetes on Proxmox Terraform Commands"
	@echo "=========================================="
	@echo "make init       - Initialize Terraform"
	@echo "make validate   - Validate Terraform configuration"
	@echo "make fmt        - Format Terraform files"
	@echo "make plan       - Generate Terraform plan"
	@echo "make apply      - Apply Terraform configuration"
	@echo "make destroy    - Destroy all created resources"
	@echo "make state      - Show current state"
	@echo "make output     - Show outputs"
	@echo "make graph      - Generate resource graph"

init:
	@echo "Initializing Terraform..."
	terraform init

validate:
	@echo "Validating Terraform configuration..."
	terraform validate

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

plan:
	@echo "Planning Terraform deployment..."
	terraform plan -out=tfplan

apply: plan
	@echo "Applying Terraform configuration..."
	terraform apply tfplan
	@echo "✓ Kubernetes cluster deployment complete!"
	@echo "Run 'make output' to see cluster details"

destroy:
	@echo "WARNING: This will destroy all created resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy; \
	else \
		echo "Destroy cancelled"; \
	fi

state:
	@terraform show

output:
	@terraform output

graph:
	@terraform graph | dot -Tsvg > graph.svg
	@echo "Resource graph saved to graph.svg"

clean:
	@rm -rf .terraform terraform.tfstate* tfplan .terraform.lock.hcl
	@echo "Cleaned up Terraform files"

check-vars:
	@echo "Checking if terraform.tfvars exists..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "✗ terraform.tfvars not found!"; \
		echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"; \
		exit 1; \
	else \
		echo "✓ terraform.tfvars found"; \
	fi

setup: init validate check-vars
	@echo "Terraform setup complete!"
	@echo "Next: Run 'make plan' to review changes"

all: setup apply

.DEFAULT_GOAL := help
