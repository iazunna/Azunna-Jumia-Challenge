# Azunna-Jumia-Challenge

# Usage Guide

## Setup Terraform Backend

```bash
./scripts/setup.sh
```

## Plan Terraform

```bash
cd infrastructure/
terraform init
terraform plan
```

## Apply Terraform

```bash
cd infrastructure/
terraform init
terraform apply -auto-approve
```

## Run Migrations

- use `scripts/db-migrations.sh` on the bastion host to run migrations.
