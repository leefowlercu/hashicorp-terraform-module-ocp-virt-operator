# Terraform Module OCP Virt Operator

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9-7B42BC?logo=terraform)](https://www.terraform.io/)

A Terraform module for deploying OpenShift Virtualization (CNV) on Red Hat OpenShift Container Platform clusters.

**Current Version**: N/A

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Providers](#providers)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Usage](#usage)
- [Architecture](#architecture)

## Overview

This Terraform root module automates the deployment and configuration of OpenShift Virtualization (CNV) on a Red Hat OpenShift Container Platform (OCP) cluster. It handles the complete operator lifecycle through the Operator Lifecycle Manager (OLM).

**Key Features:**

- Creates the `openshift-cnv` namespace with cluster monitoring enabled
- Installs the OpenShift Virtualization operator via OLM subscription
- Deploys the HyperConverged resource for full virtualization capabilities
- Implements a two-phase workflow to handle CRD installation timing
- Integrates with Terraform Enterprise for remote state management

## Quick Start

1. **Prerequisites:**
   - Terraform >= 1.9
   - Access to an OpenShift Container Platform cluster
   - Terraform Enterprise workspace with ROSA cluster outputs

2. **Configure the module:**

   ```hcl
   # terraform.tf - already configured in this module
   terraform {
     required_version = ">= 1.9"
   }
   ```

3. **Phase 1 - Install the operator:**

   ```bash
   terraform init
   terraform apply
   ```

4. **Phase 2 - Deploy HyperConverged (after CRDs are installed):**

   ```bash
   terraform apply -var="enable_hyperconverged=true"
   ```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| kubernetes | ~> 3.0 |
| tfe | ~> 0.72 |

**Prerequisites:**

- Red Hat OpenShift Container Platform cluster (ROSA or self-managed)
- Terraform Enterprise workspace containing cluster connection details
- Service account with cluster-admin privileges

## Providers

| Name | Version | Purpose |
|------|---------|---------|
| hashicorp/kubernetes | ~> 3.0 | Manages Kubernetes/OpenShift resources |
| hashicorp/tfe | ~> 0.72 | Retrieves cluster connection details from TFE workspace |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_hyperconverged | Enable creation of HyperConverged resource. Set to true after the operator has installed the CRD. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| openshift_cnv_namespace | Name of the OpenShift Virtualization namespace. |
| cnv_operator_installed | Indicates whether the OpenShift Virtualization operator subscription was created. |
| cnv_hyperconverged_deployed | Indicates whether the HyperConverged resource was deployed. |

## Usage

### Basic Usage

This module requires a two-phase apply due to CRD dependencies:

```hcl
# Phase 1: Install the operator (CRDs not yet available)
variable "enable_hyperconverged" {
  default = false
}

# Phase 2: Deploy HyperConverged (after CRDs are installed)
variable "enable_hyperconverged" {
  default = true
}
```

### Two-Phase Workflow

The OpenShift Virtualization operator installs Custom Resource Definitions (CRDs) asynchronously. The `HyperConverged` CRD is not available until after the operator subscription completes.

**Phase 1:** Apply with `enable_hyperconverged = false` (default)

```bash
terraform apply
```

This creates:
- `openshift-cnv` namespace
- OperatorGroup for operator scoping
- Subscription to the `kubevirt-hyperconverged` operator

**Phase 2:** Wait for the operator to install CRDs, then apply with `enable_hyperconverged = true`

```bash
# Verify CRD is available
oc get crd hyperconvergeds.hco.kubevirt.io

# Deploy HyperConverged
terraform apply -var="enable_hyperconverged=true"
```

### Environment-Specific Configuration

Use tfvars files for different environments:

```bash
# Development
terraform apply -var-file="environments/dev.tfvars"

# Production
terraform apply -var-file="environments/prod.tfvars"
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     TFE Workspace                               │
│                  (ocp-virt-cluster-rosa)                        │
│                                                                 │
│  Outputs:                                                       │
│    - cluster_api_url                                            │
│    - cluster_token                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              terraform-module-ocp-virt-operator                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Phase 1: Operator Installation                                 │
│  ┌──────────────────┐                                           │
│  │ openshift-cnv    │                                           │
│  │   Namespace      │                                           │
│  └────────┬─────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                           │
│  │  OperatorGroup   │                                           │
│  │  (kubevirt-      │                                           │
│  │   hyperconverged)│                                           │
│  └────────┬─────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                           │
│  │  Subscription    │───────────▶ redhat-operators catalog      │
│  │  (stable channel)│            (openshift-marketplace)        │
│  └────────┬─────────┘                                           │
│           │                                                     │
│  Phase 2: Virtualization Deployment (enable_hyperconverged=true)│
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐                                           │
│  │ HyperConverged   │                                           │
│  │   Resource       │                                           │
│  └──────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Resource Dependencies:**

1. **Namespace** - Created first with cluster monitoring labels
2. **OperatorGroup** - Scopes the operator to the namespace
3. **Subscription** - Triggers operator installation from OLM
4. **HyperConverged** - Deploys the full virtualization stack (Phase 2)
