# DevopsChallenge-infra

Concourse pipeline’ları.
Amaç: **backend**, **frontend** ve **postgres**’i CI/CD ile **tek komutla** kurup güncellemek — sırları güvenle yerelde tutarak.

---

## Klasör Yapısı

```text
DevopsChallenge-infra/
  backend-pipeline.yml
  frontend-pipeline.yml
  postgres-pipeline.yml
  credentials.example.yml  # örnek şablon credential.yml olarak değişecek.
  README.md
```
---

## Önkoşullar

- Çalışan **Concourse** ve **fly** CLI
- Bir **Kubernetes** kümesi (örn. Docker Desktop K8s)
- **Docker Registry** hesabı (örn. Docker Hub)
- Kube erişimi için **kubeconfig**

---

## Kurulum Adımları

### 1) Concourse’a giriş

```bash
fly -t main login -c http://<concourse-url> -u <user> -p <pass>
```

### 2) Repoyu İndirme

```bash
git clone git@github.com:eminekibar/DevopsChallenge-infra.git
```

### 2) Sır dosyasını hazırlama

1. `credentials.example.yml` dosyasını **gerçek değerlerle** doldur:
   - **kubeconfig_b64**: kubeconfig’inin base64 içeriği  
     - Linux/macOS: `base64 -w0 ~/.kube/config`  
     - PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config"))`
   - **docker_auth_config**: Registry kimlik bilgilerin (Docker Hub için `auth` = `base64(username:password)`)
   - Uygulama/DB sırları: `db_password` vb.
   - credentials.yml olarak adlandır.

> `credentials.yml` **asla** commitlenmez; `.gitignore` bunu engeller.

### 3) Pipeline’ları set etme

```bash
# Backend
fly -t main set-pipeline -p backend \
  -c concourse/pipelines/backend-pipeline.yml \
  -l credentials.yml

# Frontend
fly -t main set-pipeline -p frontend \
  -c frontend-pipeline.yml \
  -l credentials.yml

# Postgres
fly -t main set-pipeline -p postgres \
  -c postgres-pipeline.yml \
  -l credentials.yml
```

### 4) Pipeline’ları başlatma

```bash
fly -t main unpause-pipeline -p backend
fly -t main unpause-pipeline -p frontend
fly -t main unpause-pipeline -p postgres
```

İlk işleri tetiklemek istersen:
```bash
# Backend
fly -t main trigger-job -j backend/build-backend
fly -t main trigger-job -j backend/deploy-backend
fly -t main trigger-job -j backend/test-backend-smoke

# Frontend
fly -t main trigger-job -j frontend/build-frontend
fly -t main trigger-job -j frontend/deploy-frontend
fly -t main trigger-job -j frontend/test-frontend-smoke

# Postgres
fly -t main trigger-job -j postgres/deploy-db
```
