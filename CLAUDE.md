# CLAUDE.md

Guidance for working in this repo. See `README.md` for the full walkthrough; this
file is the short list of standards to follow when making changes.

## Golden rule: never mutate the cluster

Do **not** run `terragrunt apply`, `terraform apply`, `helm install/upgrade`,
`kubectl apply/delete/patch`, `destroy_cluster.sh`, or anything else that changes
cluster or cloud state. The user runs every apply themselves.

Allowed: config edits plus read-only checks — `terragrunt validate`,
`terragrunt plan`, `terragrunt hcl fmt`, `terraform fmt`,
`kubectl get/describe/logs`. After editing, hand the user the exact apply
commands to run. If verifying something seems to require an apply, stop and ask.

## What this is

Terragrunt repo for a self-managed Kubernetes cluster on **Proxmox** — no cloud
provider. Providers are `kubernetes` + `helm`, authenticated from a local
kubeconfig. State is **local**, one tfstate per unit under `.terragrunt-state/`.

## Layout

```
root.hcl        includes into every unit: local backend + generated providers.tf + merged inputs
common.hcl      centralized NON-secret config (kubeconfig, domain, acme_email)
secret.hcl      centralized secrets, git-ignored (secret.hcl.example is the template)
modules/<name>/ one module per platform component — no shared helm wrapper
live/platform/<name>/  one unit per component: picks a module, passes inputs, includes root
```

Components (and apply order): `namespaces` → `metallb` → `metallb-config`
(`modules/metallb-pool`) → `ingress-nginx` → `cert-manager` → `cluster-issuer` →
`external-dns` → `headlamp`. `dependencies` blocks encode this; they only enforce
order under `terragrunt run --all`.

Namespaces: everything network-layer (`metallb`, `ingress-nginx`, `cert-manager`,
`cluster-issuer`, `external-dns`) runs in **`networking`**; `headlamp` runs in
**`monitoring`**. Non-`namespaces` modules set `create_namespace = false` and
their unit depends on `../namespaces`.

## Provider rules

- `root.hcl` generates `providers.tf` for every unit: the provider blocks **and**
  `required_providers` (kubernetes `~> 2.35`, helm `~> 2.17`).
- Modules declare **no `required_providers`** of their own — it conflicts with the
  generated block.
- helm is pinned to **v2** on purpose. The generated `provider "helm" {
  kubernetes { ... } }` is v2 syntax; do not bump to helm v3 unless you also
  migrate that block in `root.hcl`.
- Delete any stray `modules/*/.terraform.lock.hcl` (Terragrunt copies the
  generated lock back into the source dir and can wrongly pin a provider).

## Module skeleton (every module identical)

Three files only — **`main.tf`, `vars.tf` (not `variables.tf`), `outputs.tf`**.
No `locals.tf`.

- `main.tf` opens with one `locals` block: first a passthrough local per input
  var (`local.x = var.x`), then fixed values (`release`, `namespace`,
  `repository`, `chart`, and a values map).
- Resources and outputs reference **`local.*` only**, never `var.*`.
- helm modules with flat values build `set {}` via `dynamic "set"` over the
  values map. Modules with nested values (`external-dns`, `headlamp`) instead
  pass `values = [yamlencode(local.values)]` — nested maps and dotted keys don't
  survive `set` blocks. Keep both branches of a `?:` the same type.
- `helm_release` args used here: `atomic = true`, `wait = true`, `timeout = 600`,
  `max_history = 10`.
- Every var has a `description`; secret vars also set `sensitive = true`.

## Unit rules (`live/platform/<name>/terragrunt.hcl`)

- Always `include "root"` via `find_in_parent_folders("root.hcl")` and set
  `terraform.source` to `${get_parent_terragrunt_dir()}/modules/<name>`.
- Always an **explicit `inputs` block**, even when it only restates module
  defaults.
- Add a `dependencies { paths = [...] }` block for ordering.

## Centralized config

`root.hcl` does `inputs = merge(common.hcl locals, secret.hcl locals)` — every
local in both files is passed to **every** unit; a module just declares the
`variable` it consumes, undeclared inputs are dropped by Terraform.

- Non-secret, shared → add to `common.hcl`. Secret → add to `secret.hcl` **and**
  `secret.hcl.example`. Never commit a real secret.
- Units consuming only centralized config (e.g. `cluster-issuer`) may still carry
  an `inputs` block but pass nothing extra.

## Adding a component

1. `modules/<name>/` with the 3-file skeleton above (no `required_providers`).
2. `live/platform/<name>/terragrunt.hcl` pointing `source` at it, with an
   explicit `inputs` block and any `dependencies`.
3. If it needs a namespace, put it in `networking` or `monitoring`, set
   `create_namespace = false`, depend on `../namespaces`, and add the namespace
   (with any PSA labels) to `modules/namespaces` input in
   `live/platform/namespaces/terragrunt.hcl`.
4. Update `README.md` and `destroy_cluster.sh` if the component is user-facing.

## Environment

Terragrunt **v1.1.1** (redesigned CLI): `terragrunt run --all <cmd>`,
`terragrunt hcl fmt`, `terragrunt render` — **not** `run-all` / `hclfmt` /
`render-json`. Terraform v1.15.8. Cluster k8s v1.36.4 (1 master + 1 worker).
