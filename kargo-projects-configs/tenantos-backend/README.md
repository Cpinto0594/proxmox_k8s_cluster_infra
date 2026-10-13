# Kargo promotion (dev -> qa -> prod)

Flow: push -> CI builds `<registry>/homelab/tenantos-backend:<UTC timestamp>-<sha12>` -> Warehouse
discovers the tag -> `dev` promotes automatically -> `qa` and `prod` are promoted
manually. A promotion dispatches `.forgejo/workflows/build.yml` with `env` + `image`;
CI then runs skaffolder + `skaffold apply` for that env. Secrets never leave CI.

Setup (managed by Terraform, unit `live/platform/kargo-projects/tenantos-backend`, module `modules/kargo-project`):
```bash
# fill forgejo_dispatch_token / forgejo_registry_username / forgejo_registry_password in secret.hcl
cd live/platform/kargo-tenantos-backend && terragrunt apply
```
The unit creates the namespace, both Secrets below, and applies every YAML file in this
directory (Project, ProjectConfig, Warehouse, Stages). Edit the YAML and re-apply to change them.

## Credentials

Both live in `secret.hcl` and are Forgejo personal access tokens (Settings -> Applications -> Generate New Token),
not the account password. Use two separate tokens so a leak of one doesn't expose the other;
a dedicated Forgejo user for Kargo keeps the audit trail clear.

| Secret | Cred type | Used for | Token scope |
|---|---|---|---|
| `forgejo-registry-read` | `image` | Warehouse listing image tags. `username` is the Forgejo user, `password` is the token. | `read:package` |
| `forgejo-dispatch` | `generic` | Stages triggering the workflow (`token` key). | `write:repository` |

If the registry package is public, `forgejo-registry-read` isn't needed.

## Limitations

- Kargo marks a promotion successful once the dispatch returns 200/204; it does not wait for
  the deploy. A failed deploy shows up in the Forgejo Actions run, not in Kargo.
- dev, qa and prod must deploy to different namespaces (set `namespace` per env in
  skaffolder's configs) or they will overwrite each other.
