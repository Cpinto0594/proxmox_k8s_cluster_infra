# k8s_cluster_infra

Terragrunt configuration for a self-managed Kubernetes cluster running on Proxmox.
Providers used: **kubernetes** and **helm**, both authenticated from a kubeconfig
on the machine running Terragrunt (no cloud provider / SDK).

## Layout

```
root.hcl                       root: local state + generated kubernetes/helm providers
common.hcl                     centralized non-secret config: kubeconfig + DNS + MetalLB (edit this)
secret.hcl                     git-ignored; all secrets (cp from secret.hcl.example)
destroy_cluster.sh             kubectl/helm teardown of everything below
modules/                       one module per platform component, no shared wrapper.
  namespaces/                    each module: main.tf (locals + resources) / vars.tf / outputs.tf
  metallb/                       helm_release "metallb"
  metallb-pool/                  IPAddressPool + L2Advertisement (kubernetes_manifest)
  ingress-nginx/                 helm_release "ingress_nginx"
  cert-manager/                  helm_release "cert_manager"
  cluster-issuer/                Let's Encrypt ClusterIssuers + Cloudflare token Secret
  external-dns/                  helm_release "external_dns" (Ingress -> Cloudflare records)
  headlamp/                      helm_release "headlamp" (Kubernetes web UI)
live/
  platform/
    namespaces/                -> modules/namespaces     (monitoring / apps / networking)
    metallb/                   -> modules/metallb        (ns networking; depends on namespaces)
    metallb-config/            -> modules/metallb-pool   (ns networking; depends on metallb)
    ingress-nginx/             -> modules/ingress-nginx  (ns networking; depends on namespaces + metallb + metallb-config)
    cert-manager/              -> modules/cert-manager   (ns networking; depends on namespaces)
    cluster-issuer/            -> modules/cluster-issuer (ns networking; depends on namespaces + cert-manager)
    external-dns/              -> modules/external-dns   (ns networking; depends on namespaces + ingress-nginx)
    headlamp/                  -> modules/headlamp       (ns monitoring; depends on namespaces + ingress-nginx + cluster-issuer)
```

Each directory under `live/platform/` is a unit: it picks one module, passes a
few inputs, and includes the root `root.hcl`, which:

- writes local state to `.terragrunt-state/<unit path>/terraform.tfstate`
- generates `providers.tf` — the `kubernetes` + `helm` provider blocks and their
  version pins (`~> 2.35` / `~> 2.17`), pointed at `var.kubeconfig_path` /
  `var.kubeconfig_context`. Modules declare no `required_providers` of their own.
- merges every `local` from `common.hcl` and `secret.hcl` into the unit's
  inputs. A module just declares the `variable` it wants (`domain`, `acme_email`,
  `metallb_addresses`, `cloudflare_api_token`, …); undeclared ones are ignored.

## Setup

1. Edit `common.hcl`:
   - `kubeconfig_path` / `kubeconfig_context` — or `export KUBECONFIG=...`;
     leave the context `""` to use `kubectl`'s current-context.
   - `domain` — your Cloudflare-managed domain (ingress hostnames + the
     cert-manager DNS-01 zone derive from it).
   - `acme_email` — Let's Encrypt account email.
   - `metallb_addresses` — LoadBalancer IP range (free, outside DHCP, on an L2
     segment the nodes can ARP for).

2. Sanity-check access:

   ```bash
   kubectl get nodes
   ```

3. Create your secrets file (git-ignored):

   ```bash
   cp secret.hcl.example secret.hcl
   # then edit secret.hcl and fill in real values
   ```

   Every `local` in `secret.hcl` is passed to every unit as an input; a module
   just declares the `variable` it needs (e.g. `cloudflare_api_token`). Units
   that need no secret still work if the file is absent.

## Usage

### Order matters

`ingress-nginx` publishes a `type: LoadBalancer` Service. On bare metal nothing
assigns it an external IP until **MetalLB** is running **and** an
`IPAddressPool` exists, so it must be applied in this order:

```
namespaces        monitoring / apps / networking
metallb           MetalLB chart (CRDs + controller + speaker)   [ns networking]
metallb-config    IPAddressPool + L2Advertisement   <- range is metallb_addresses in common.hcl
ingress-nginx     depends on namespaces + metallb + metallb-config   [ns networking]
cert-manager      depends on namespaces   [ns networking]
cluster-issuer    depends on namespaces + cert-manager   <- needs cloudflare_api_token in secret.hcl
external-dns      depends on namespaces + ingress-nginx  <- needs cloudflare_api_token in secret.hcl
headlamp          depends on namespaces + ingress-nginx + cluster-issuer   [ns monitoring]
```

`metallb`, `ingress-nginx`, `cert-manager`, `cluster-issuer` (its token Secret)
and `external-dns` all live in the **`networking`** namespace, created by the
`namespaces` unit. Its input is `namespace => { service => labels }`; the module
unions each service's labels onto the namespace, so MetalLB's
`pod-security.kubernetes.io/enforce=privileged` (declared under `metallb`) is
applied to the whole `networking` namespace.

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
cd ../cluster-issuer            && terragrunt apply   # needs cloudflare_api_token in secret.hcl
cd ../external-dns              && terragrunt apply   # needs cloudflare_api_token in secret.hcl
cd ../headlamp                  && terragrunt apply
```

> Built and tested against Terragrunt **v1.1.1** (the redesigned CLI). On that
> version the stack command is `terragrunt run --all <cmd>`; the old
> `terragrunt run-all <cmd>` and `terragrunt hclfmt` / `render-json` spellings
> are gone. Everything in the `.hcl` files (named `include`, `generate`,
> `remote_state`, `dependencies`, `read_terragrunt_config`) is supported as-is.

### Teardown

`./destroy_cluster.sh` removes everything above via `kubectl` + `helm` directly
(no dependency on Terragrunt state, which has proven unreliable): cert-manager
CRs, the Cloudflare records external-dns made, all 5 Helm releases, leftover
CRDs, the namespaces, and stray cluster-scoped RBAC/webhooks. Idempotent.

```bash
./destroy_cluster.sh            # confirms first
./destroy_cluster.sh -y --local # no prompt; also wipe local .terragrunt-state / caches
```

If Terragrunt state is intact, `cd live && terragrunt run --all destroy` also works.

## MetalLB address range

Edit `metallb_addresses` in `common.hcl`:

```hcl
metallb_addresses = ["192.168.30.200-192.168.30.250"]   # must be free + outside DHCP
```

The range must be on an L2 segment the nodes can ARP for (a NIC/VLAN on that
subnet), or MetalLB L2 mode can't announce it. `modules/metallb-pool` uses
`kubernetes_manifest`, which validates against the MetalLB CRDs at plan time —
that is why it is a separate unit applied after the `metallb` chart.

## TLS / Cloudflare

`cluster-issuer` creates two Let's Encrypt `ClusterIssuer`s —
`letsencrypt-staging` and `letsencrypt-prod` — that solve ACME **DNS-01**
challenges through the Cloudflare API. DNS-01 means the hostname never needs to
be reachable over HTTP from the internet, so it works for LAN-only services.

1. Create a Cloudflare **API token** (My Profile → API Tokens) with
   `Zone → DNS → Edit` and `Zone → Zone → Read`, scoped to your zone.
2. Put it in `secret.hcl`:

   ```hcl
   locals {
     cloudflare_api_token = "..."
   }
   ```

3. Make sure `domain` + `acme_email` are set in `common.hcl` (the DNS-01 solver
   is scoped to `domain`). Then apply:

   ```bash
   cd live/platform/cluster-issuer && terragrunt apply
   kubectl get clusterissuers.cert-manager.io   # wait for READY=True
   ```

The token flows from `secret.hcl` through `root.hcl` into the module, which
writes it to a `cloudflare-api-token` Secret in the `networking` namespace (where
cert-manager runs) — nothing secret is committed. `modules/cluster-issuer` uses
`kubernetes_manifest`, so it depends on the `cert-manager` unit (CRDs must exist
at plan time), same as `metallb-pool`.

Consumers reference an issuer by name. `headlamp` uses `letsencrypt-prod` and is
served at `headlamp.<domain>` (`subdomain` in its unit + `domain` from
`common.hcl`); while iterating on a new Ingress, switch `cluster_issuer` to
`letsencrypt-staging` to avoid Let's Encrypt rate limits (the cert will be
browser-untrusted).

## DNS / Cloudflare

`external-dns` watches `Ingress` objects and creates the matching Cloudflare
records for `<host> -> <ingress-nginx LoadBalancer IP>` automatically. Apply it
once (`domain` from `common.hcl`, token from `secret.hcl`) and every app's DNS
record then appears without touching Cloudflare by hand.

- The LB IP (`192.168.30.200`) is private, so records are **DNS-only** (grey
  cloud, `proxied = false`) — they only resolve usefully on the LAN. This is
  inherent to a private LoadBalancer IP, not a limitation of `external-dns`.
- `policy = "upsert-only"` (default) never deletes. Switch to `"sync"` to let it
  prune records it owns (tracked via a TXT registry record keyed by
  `txt_owner_id` — keep that value stable).
- Only `Ingress` is watched. Add `"service"` to `sources` to also manage
  `type: LoadBalancer` Services.

external-dns runs in `networking` and uses its own
`external-dns-cloudflare-api-token` Secret (distinct from the cluster-issuer one
in the same namespace).

```bash
kubectl -n networking logs deploy/external-dns | grep -Ei 'CREATE|UPDATE'
dig +short headlamp.capilabs.dev @1.1.1.1        # -> 192.168.30.200 once propagated
```

## Troubleshooting

**`release ingress-nginx failed ... context deadline exceeded` (atomic rollback)**
The controller Service never got an external IP. Check:

```bash
kubectl get pods -n networking -l app.kubernetes.io/name=metallb   # controller + speaker Running?
kubectl get ipaddresspools.metallb.io -n networking
kubectl get svc -n networking ingress-nginx-controller             # EXTERNAL-IP still <pending>?
```

Fix: apply `metallb` then `metallb-config` before re-applying `ingress-nginx`.

## Adding a component

1. `modules/<name>/` — one module per component, same 3-file skeleton every time
   (`main.tf`, `vars.tf`, `outputs.tf`). Do not add `required_providers`; the
   root generates them.

   `main.tf` opens with a `locals` block: one passthrough local per input
   variable (`local.x = var.x`), then the fixed values. Resources reference
   `local.*` only — never `var.*` directly.

   ```hcl
   # vars.tf
   variable "chart_version" {
     type    = string
     default = "1.2.3"
   }
   ```

   ```hcl
   # main.tf
   locals {
     chart_version = var.chart_version

     release    = "<name>"
     namespace  = "<name>"
     repository = "https://charts.example.com"
     chart      = "<chart>"

     helm_values = {
       "some.key" = "value"
     }
   }

   resource "helm_release" "<name>" {
     name             = local.release
     namespace        = local.namespace
     create_namespace = true

     repository = local.repository
     chart      = local.chart
     version    = local.chart_version

     dynamic "set" {
       for_each = local.helm_values
       content {
         name  = set.key
         value = set.value
       }
     }

     atomic  = true
     wait    = true
     timeout = 600
   }
   ```

   ```hcl
   # outputs.tf
   output "name"      { value = helm_release.<name>.name }
   output "namespace" { value = helm_release.<name>.namespace }
   ```

2. `live/platform/<name>/terragrunt.hcl` — always an explicit `inputs` block:

   ```hcl
   include "root" {
     path = find_in_parent_folders("root.hcl")
   }

   terraform {
     source = "${get_parent_terragrunt_dir()}/modules/<name>"
   }

   dependencies {
     paths = ["../namespaces"] # optional
   }

   inputs = {
     chart_version = "1.2.3"
   }
   ```
