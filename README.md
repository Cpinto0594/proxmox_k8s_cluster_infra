# k8s_cluster_infra

Terragrunt configuration for a self-managed Kubernetes cluster running on Proxmox.
Providers used: **kubernetes** and **helm**, both authenticated from a kubeconfig
on the machine running Terragrunt (no cloud provider / SDK).

## Layout

```
root.hcl                       root: local state + generated kubernetes/helm providers
common.hcl                     kubeconfig path + context (edit this)
modules/                       one module per platform component, each with its
  namespaces/                    own explicit resources (no shared wrapper)
  metallb/                       helm_release "metallb"
  metallb-pool/                  IPAddressPool + L2Advertisement (kubernetes_manifest)
  ingress-nginx/                 helm_release "ingress_nginx"
  cert-manager/                  helm_release "cert_manager"
live/
  platform/
    namespaces/                -> modules/namespaces
    metallb/                   -> modules/metallb        (depends on namespaces)
    metallb-config/            -> modules/metallb-pool   (depends on metallb)
    ingress-nginx/             -> modules/ingress-nginx  (depends on metallb + metallb-config)
    cert-manager/              -> modules/cert-manager
```

Each directory under `live/platform/` is a unit: it picks one module, passes a
few inputs, and includes the root `root.hcl`, which:

- writes local state to `.terragrunt-state/<unit path>/terraform.tfstate`
- generates `providers.tf` — the `kubernetes` + `helm` provider blocks and their
  version pins (`~> 2.35` / `~> 2.17`), pointed at `var.kubeconfig_path` /
  `var.kubeconfig_context`. Modules declare no `required_providers` of their own.

## Setup

1. Point `common.hcl` at your kubeconfig, or export one:

   ```bash
   export KUBECONFIG=~/.kube/proxmox-cluster.yaml
   ```

   Set `kubeconfig_context` in `common.hcl` to your context name, or `null` to
   use the current context.

2. Sanity-check access:

   ```bash
   kubectl get nodes
   ```

## Usage

### Order matters

`ingress-nginx` publishes a `type: LoadBalancer` Service. On bare metal nothing
assigns it an external IP until **MetalLB** is running **and** an
`IPAddressPool` exists, so it must be applied in this order:

```
namespaces        monitoring / apps / metallb-system
metallb           MetalLB chart (CRDs + controller + speaker)
metallb-config    IPAddressPool + L2Advertisement   <- edit the range here
ingress-nginx     depends on metallb + metallb-config
cert-manager      (independent)
```

Apply the whole stack in dependency order:

```bash
cd live
terragrunt run --all plan
terragrunt run --all apply
```

Or one unit at a time (respect the order above):

```bash
cd live/platform/namespaces     && terragrunt apply
cd ../metallb                   && terragrunt apply
cd ../metallb-config            && terragrunt apply
cd ../ingress-nginx             && terragrunt apply
cd ../cert-manager              && terragrunt apply
```

> Built and tested against Terragrunt **v1.1.1** (the redesigned CLI). On that
> version the stack command is `terragrunt run --all <cmd>`; the old
> `terragrunt run-all <cmd>` and `terragrunt hclfmt` / `render-json` spellings
> are gone. Everything in the `.hcl` files (named `include`, `generate`,
> `remote_state`, `dependencies`, `read_terragrunt_config`) is supported as-is.

## MetalLB address range

Edit the range in `live/platform/metallb-config/terragrunt.hcl`:

```hcl
inputs = {
  pool_name = "lan"
  addresses = ["192.168.1.240-192.168.1.250"]   # must be free + outside DHCP
}
```

`modules/metallb-pool` uses `kubernetes_manifest`, which validates against the
MetalLB CRDs at plan time — that is why it is a separate unit applied after the
`metallb` chart, not part of it.

## Troubleshooting

**`release ingress-nginx failed ... context deadline exceeded` (atomic rollback)**
The controller Service never got an external IP. Check:

```bash
kubectl get pods -n metallb-system                    # controller + speaker Running?
kubectl get ipaddresspools.metallb.io -n metallb-system
kubectl get svc -n ingress-nginx                      # EXTERNAL-IP still <pending>?
```

Fix: apply `metallb` then `metallb-config` before re-applying `ingress-nginx`.

## Adding a component

1. `modules/<name>/` — one module per component. Do not add `required_providers`;
   the root generates them. Split as:
   - `main.tf` — the `helm_release` (or other resources), explicit
   - `vars.tf` — input variables (omit if none)
   - `outputs.tf` — outputs

   ```hcl
   # main.tf
   resource "helm_release" "<name>" {
     name             = "<name>"
     namespace        = "<name>"
     create_namespace = true

     repository = "https://charts.example.com"
     chart      = "<chart>"
     version    = var.chart_version

     atomic  = true
     wait    = true
     timeout = 600
   }
   ```

   ```hcl
   # vars.tf
   variable "chart_version" {
     type    = string
     default = "1.2.3"
   }
   ```

2. `live/platform/<name>/terragrunt.hcl`:

   ```hcl
   include "root" {
     path = find_in_parent_folders("root.hcl")
   }

   terraform {
     source = "${get_parent_terragrunt_dir()}/modules/<name>"
   }

   # optional
   dependencies {
     paths = ["../namespaces"]
   }
   ```
