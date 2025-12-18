# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform root module that deploys OpenShift Virtualization (CNV) on Red Hat OpenShift Container Platform clusters via Operator Lifecycle Manager (OLM).

## Commands

```bash
# Initialize
terraform init

# Format
terraform fmt

# Validate
terraform validate

# Plan
terraform plan -var-file="environments/dev.tfvars"

# Apply Phase 1 (operator installation)
terraform apply

# Apply Phase 2 (HyperConverged deployment)
terraform apply -var="enable_hyperconverged=true"

# Verify CRD availability before Phase 2
oc get crd hyperconvergeds.hco.kubevirt.io
```

## Architecture

This module implements a **two-phase workflow** due to CRD timing dependencies:

**Phase 1** (`enable_hyperconverged=false`): Creates namespace, OperatorGroup, and Subscription. The operator installs CRDs asynchronously.

**Phase 2** (`enable_hyperconverged=true`): Creates HyperConverged resource after CRDs are available.

**Resource dependency chain:**
```
Namespace → OperatorGroup → Subscription → HyperConverged (Phase 2)
```

**External dependency:** Retrieves cluster connection details (`cluster_api_url`, `cluster_token`) from TFE workspace `ocp-virt-cluster-rosa` via `data.tfe_outputs`.

## File Organization

| File | Purpose |
|------|---------|
| `main.tf` | Kubernetes resources (namespace, OperatorGroup, Subscription, HyperConverged) |
| `data.tf` | TFE outputs data source for cluster connection |
| `providers.tf` | kubernetes and tfe provider configuration |
| `terraform.tf` | Required versions and providers |
| `variables.tf` | Input variables |
| `outputs.tf` | Module outputs |
| `environments/*.tfvars` | Environment-specific variable values |

## Key Patterns

- **Lifecycle ignore_changes**: Namespace ignores OpenShift-managed annotations/labels to prevent drift
- **Conditional resources**: HyperConverged uses `count` based on `enable_hyperconverged` variable
- **Explicit depends_on**: Enforces OLM resource ordering
