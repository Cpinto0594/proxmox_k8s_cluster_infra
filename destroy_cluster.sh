#!/usr/bin/env bash
#
# destroy_cluster.sh — remove every component this repo deploys.
#
# Direct kubectl/helm teardown, independent of Terragrunt state (state has been
# unreliable). Idempotent: safe to re-run, safe to run when nothing is installed.
#
#   ./destroy_cluster.sh            # prompts for confirmation
#   ./destroy_cluster.sh -y         # no prompt
#   ./destroy_cluster.sh -y --local # also wipe local .terragrunt-state / caches
#
# If Terragrunt state happens to be intact you can instead use the normal path:
#   (cd live && terragrunt run --all destroy)
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# --------------------------------------------------------------------------
# what we manage
# --------------------------------------------------------------------------
NAMESPACES=(networking monitoring apps)

# release:namespace  — listed in reverse dependency order (uninstalled top-down)
RELEASES=(
  "headlamp:monitoring"
  "external-dns:networking"
  "ingress-nginx:networking"
  "cert-manager:networking"
  "metallb:networking"
)

CRD_MATCH='\.cert-manager\.io$|\.metallb\.io$'
CLUSTER_SCOPED_MATCH='cert-manager|metallb|ingress-nginx|external-dns'

# --------------------------------------------------------------------------
# args
# --------------------------------------------------------------------------
ASSUME_YES=0
CLEAN_LOCAL=0
for a in "$@"; do
  case "$a" in
    -y|--yes)   ASSUME_YES=1 ;;
    --local)    CLEAN_LOCAL=1 ;;
    -h|--help)  sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*"; }

command -v kubectl >/dev/null || { echo "kubectl not found in PATH"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo "cannot reach the cluster (check KUBECONFIG)"; exit 1; }

if [ "$ASSUME_YES" -ne 1 ]; then
  ctx="$(kubectl config current-context 2>/dev/null || echo '?')"
  read -rp "Delete ALL repo components from context '$ctx'? [y/N] " ans
  [[ "$ans" == y || "$ans" == Y ]] || { echo "aborted"; exit 0; }
fi

# --------------------------------------------------------------------------
# helm (download a throwaway copy if not installed)
# --------------------------------------------------------------------------
HELM="$(command -v helm || true)"
if [ -z "$HELM" ]; then
  log "helm not in PATH — fetching a local copy"
  TMPBIN="$(mktemp -d)"; trap 'rm -rf "$TMPBIN"' EXIT
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | HELM_INSTALL_DIR="$TMPBIN" USE_SUDO=false bash >/dev/null 2>&1 || true
  HELM="$TMPBIN/helm"
  [ -x "$HELM" ] || { echo "could not obtain helm"; exit 1; }
fi

# --------------------------------------------------------------------------
# read a  key = "value"  line out of an HCL file (ignores trailing # comments)
# --------------------------------------------------------------------------
hcl_val() {
  grep -E "^[[:space:]]*$2[[:space:]]*=" "$1" 2>/dev/null | head -1 \
    | sed -E 's/.*=[[:space:]]*"?([^"#]*)"?.*/\1/' | xargs
}
DOMAIN="$(hcl_val common.hcl domain)"
CF_OWNER="$(hcl_val live/platform/external-dns/terragrunt.hcl txt_owner_id)"
CF_TOKEN="$(hcl_val secret.hcl cloudflare_api_token)"

# ==========================================================================
# 1. cert-manager CRs first, while its controller can still run finalizers
# ==========================================================================
log "Deleting cert-manager resources (Certificates / Issuers / ACME orders)"
kubectl delete clusterissuer --all --ignore-not-found --timeout=60s 2>/dev/null || true
for ns in "${NAMESPACES[@]}"; do
  kubectl -n "$ns" delete certificate,certificaterequest,order,challenge \
    --all --ignore-not-found --timeout=60s 2>/dev/null || true
done

# ==========================================================================
# 2. Cloudflare records external-dns created (best effort; needs token + python3)
# ==========================================================================
log "Cleaning Cloudflare DNS records for owner '$CF_OWNER'"
if [ -z "$CF_TOKEN" ]; then
  warn "no cloudflare_api_token in secret.hcl — delete external-dns records manually"
elif ! command -v python3 >/dev/null; then
  warn "python3 not available — delete external-dns records manually"
else
  python3 - "$CF_TOKEN" "$DOMAIN" "$CF_OWNER" <<'PY' || warn "Cloudflare cleanup failed — check manually"
import sys, json, urllib.request
token, domain, owner = sys.argv[1], sys.argv[2], sys.argv[3]
def api(path, method="GET"):
    r = urllib.request.Request("https://api.cloudflare.com/client/v4" + path, method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r))
zs = api(f"/zones?name={domain}").get("result") or []
if not zs:
    print(f"  zone {domain} not found"); sys.exit(0)
zid = zs[0]["id"]
recs = api(f"/zones/{zid}/dns_records?per_page=50000").get("result") or []
names = set()
for r in recs:
    if r["type"] == "TXT" and f"external-dns/owner={owner}" in r.get("content", ""):
        names.add(r["name"])
        n = r["name"]
        for p in ("a-", "aaaa-", "cname-", "txt-"):
            if n.startswith(p): names.add(n[len(p):]); break
victims = [r for r in recs if r["name"] in names]
for r in victims:
    api(f"/zones/{zid}/dns_records/{r['id']}", method="DELETE")
    print(f"  deleted {r['type']:5} {r['name']}")
print("  nothing to delete" if not victims else f"  removed {len(victims)} record(s)")
PY
fi

# ==========================================================================
# 3. uninstall the Helm releases
# ==========================================================================
log "Uninstalling Helm releases"
for entry in "${RELEASES[@]}"; do
  rel="${entry%%:*}"; ns="${entry##*:}"
  if "$HELM" status "$rel" -n "$ns" >/dev/null 2>&1; then
    "$HELM" uninstall "$rel" -n "$ns" --wait --timeout 5m || warn "uninstall $rel/$ns failed"
  else
    echo "  $rel/$ns — not installed"
  fi
done

# ==========================================================================
# 4. CRDs Helm keeps behind (deleting a CRD also deletes its CRs)
# ==========================================================================
log "Deleting leftover CRDs"
mapfile -t CRDS < <(kubectl get crd -o name 2>/dev/null | grep -E "$CRD_MATCH" || true)
if [ "${#CRDS[@]}" -gt 0 ]; then kubectl delete "${CRDS[@]}" --ignore-not-found; else echo "  none"; fi

# ==========================================================================
# 5. namespaces (sweeps any remaining namespaced objects + release secrets)
# ==========================================================================
log "Deleting namespaces: ${NAMESPACES[*]}"
kubectl delete ns "${NAMESPACES[@]}" --ignore-not-found --timeout=180s || \
  warn "a namespace is stuck terminating — check 'kubectl get ns' for finalizers"

# ==========================================================================
# 6. sweep stray cluster-scoped resources the charts own
# ==========================================================================
log "Sweeping stray cluster-scoped resources"
for kind in clusterrole clusterrolebinding validatingwebhookconfiguration \
            mutatingwebhookconfiguration apiservice; do
  mapfile -t ITEMS < <(kubectl get "$kind" -o name 2>/dev/null | grep -Ei "$CLUSTER_SCOPED_MATCH" || true)
  [ "${#ITEMS[@]}" -gt 0 ] && kubectl delete "${ITEMS[@]}" --ignore-not-found
done
# the IngressClass is named "nginx"; only remove it if ingress-nginx owned it
if kubectl get ingressclass nginx -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' 2>/dev/null \
     | grep -q ingress-nginx; then
  kubectl delete ingressclass nginx --ignore-not-found
fi

# ==========================================================================
# 7. local Terragrunt artifacts (opt-in)
# ==========================================================================
if [ "$CLEAN_LOCAL" -eq 1 ]; then
  log "Removing local Terragrunt state + caches"
  rm -rf .terragrunt-state
  find . -type d -name .terragrunt-cache -exec rm -rf {} + 2>/dev/null || true
  find . -name .terraform.lock.hcl -delete 2>/dev/null || true
fi

# ==========================================================================
# done
# ==========================================================================
log "Teardown complete — remaining namespaces:"
kubectl get ns
echo
echo "left alone: modules/, live/, common.hcl, secret.hcl (configs untouched)"
[ "$CLEAN_LOCAL" -eq 1 ] || echo "note: local .terragrunt-state/ kept — re-run with --local to wipe it"
