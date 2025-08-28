NS="${1:-devopschallenge}"
TIMEOUT="${TIMEOUT:-15s}"

# ===== Renkler =====
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; BOLD=""; DIM=""; RESET=""
fi

# ===== Sadece basit yazı yardımcıları =====
run(){ printf "${DIM}$ %s${RESET}\n" "$*"; eval "$@"; }
section(){ printf "\n${BOLD}${BLUE}%s${RESET}\n" "$*"; }
sub(){ printf "\n${BOLD}${CYAN}%s${RESET}\n" "$*"; }

printf "${MAGENTA}\n===== Namespace: %s =====${RESET}\n" "$NS"
printf "${DIM}Context: $(kubectl config current-context 2>/dev/null || echo n/a) | "
printf "Server: $(kubectl version 2>/dev/null | sed -n 's/^Server Version: //p' | head -n1)\n${RESET}"

# ========= FRONTEND =========
section "FRONTEND (app=frontend)"
    sub "Deployments";
        run kubectl -n "$NS" get deploy -l app=frontend
    sub "Rollout";
        run 'kubectl -n "$NS" rollout status deploy/frontend-deploy --timeout='"$TIMEOUT"' || true'
    sub "Pods (wide)";
        run kubectl -n "$NS" get pods -l app=frontend -o wide --sort-by=.status.startTime
    sub "Services";
        run kubectl -n "$NS" get svc -l app=frontend -o custom-columns='NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[*].port,TARGET:.spec.ports[*].targetPort,NODEPORT:.spec.ports[*].nodePort'
    sub "HPA";
        run 'kubectl -n "$NS" get hpa -l app=frontend || true'

# ========= BACKEND =========
section "BACKEND (app=backend)"
    sub "Deployments";
        run kubectl -n "$NS" get deploy -l app=backend
    sub "Rollout";
        run 'kubectl -n "$NS" rollout status deploy/backend-deploy --timeout='"$TIMEOUT"' || true'
    sub "Pods (wide)";
        run kubectl -n "$NS" get pods -l app=backend -o wide --sort-by=.status.startTime
    sub "Services";
        run kubectl -n "$NS" get svc -l app=backend -o custom-columns='NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[*].port,TARGET:.spec.ports[*].targetPort,NODEPORT:.spec.ports[*].nodePort'
    sub "HPA";
        run 'kubectl -n "$NS" get hpa -l app=backend || true'

# ========= POSTGRES =========
section "POSTGRES (app=postgres)"
    sub "StatefulSets";
        run kubectl -n "$NS" get sts -l app=postgres
    sub "Pods (wide)";
        run kubectl -n "$NS" get pods -l app=postgres -o wide --sort-by=.status.startTime
    sub "PVCs";
        run 'kubectl -n "$NS" get pvc -l app=postgres || true'
    sub "Services";
        run kubectl -n "$NS" get svc -l app=postgres -o custom-columns='NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[*].port,TARGET:.spec.ports[*].targetPort'

# ========= GENEL ÖZET =========
section "GENEL ÖZET"
    sub "All Services";
        run kubectl -n "$NS" get svc -o wide
    sub "All Pods";
        run kubectl -n "$NS" get pods -o wide --sort-by=.status.startTime

# Opsiyonel: metrics-server varsa 'top' göster
if kubectl top pods -n "$NS" >/dev/null 2>&1; then
  sub "CPU/MEM (top pods)"; run kubectl -n "$NS" top pods
fi

# Opsiyonel: rollout hata olursa son 20 event
# SHOW_EVENTS_ON_FAIL=1 bash tools/ms-mini.sh
if [[ "${SHOW_EVENTS_ON_FAIL:-0}" == "1" ]]; then
  section "SON OLAYLAR (Events)"
  run kubectl -n "$NS" get events --sort-by=.lastTimestamp | tail -n 20
fi
