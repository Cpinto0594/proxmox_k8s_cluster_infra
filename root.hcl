# Root Terragrunt configuration.
# Every unit under live/ includes this file, which gives it:
#   - local state (one file per unit under .terragrunt-state/)
#   - a generated kubernetes + helm provider wired to a kubeconfig on this machine

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # secret.hcl lives at the repo root, is git-ignored, and holds a single
  # `locals { ... }` block. Every key in it is passed to every unit as an input
  # (Terraform ignores TF_VAR_* it doesn't declare), so a module just declares
  # the `variable` it needs. Optional: units that need no secret work without it.
  secret_file = find_in_parent_folders("secret.hcl", "")
  secrets     = local.secret_file != "" ? read_terragrunt_config(local.secret_file).locals : {}
}

# ---------------------------------------------------------------------------
# State: local backend, one tfstate per unit.
# ---------------------------------------------------------------------------
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${get_parent_terragrunt_dir()}/.terragrunt-state/${path_relative_to_include()}/terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------
# Providers: the kubernetes + helm provider config and their version pins are
# identical for every unit and must stay in lockstep, so they are generated
# here instead of repeated in each module. Modules under modules/ only declare
# resources. Auth comes from a kubeconfig on this machine (no cloud SDK).
# ---------------------------------------------------------------------------
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.3"

      required_providers {
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.35"
        }
        helm = {
          source  = "hashicorp/helm"
          version = "~> 2.17"
        }
      }
    }

    locals {
      kube_context = var.kubeconfig_context != "" ? var.kubeconfig_context : null
    }

    provider "kubernetes" {
      config_path    = pathexpand(var.kubeconfig_path)
      config_context = local.kube_context
    }

    provider "helm" {
      kubernetes {
        config_path    = pathexpand(var.kubeconfig_path)
        config_context = local.kube_context
      }
    }

    variable "kubeconfig_path" {
      description = "Path to the kubeconfig file for the cluster."
      type        = string
    }

    variable "kubeconfig_context" {
      description = "kubeconfig context to use. \"\" or null = current-context."
      type        = string
      default     = null
      nullable    = true
    }
  EOF
}

# ---------------------------------------------------------------------------
# Inputs shared by every unit: everything in common.hcl + everything in
# secret.hcl. Modules pick up only the variables they declare; the rest are
# ignored (Terraform drops undeclared TF_VAR_*).
# ---------------------------------------------------------------------------
inputs = merge(
  local.common.locals,
  local.secrets,
)


#kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml