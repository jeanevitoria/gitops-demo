#!/usr/bin/env bash
set -euo pipefail

for tool in docker kubectl kind; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Pré-requisito ausente: $tool. Instale-o e tente novamente." >&2
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo 'Docker não está ativo ou seu usuário não tem acesso ao daemon.' >&2
  exit 1
fi

cluster_name=gitops-demo
if ! kind get clusters | grep -Fxq "$cluster_name"; then
  kind create cluster --name "$cluster_name" --wait 5m
fi

kubectl config use-context "kind-$cluster_name"
kubectl wait --for=condition=Ready node --all --timeout=180s
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$script_dir/../argocd-application.yaml"

cat <<'EOF'

Ambiente preparado. Aguarde a aplicação ficar Synced e Healthy.
Em um terminal, execute: kubectl port-forward -n gitops-demo svc/gitops-demo 8081:80
Abra: http://localhost:8081
Para a interface Argo CD, execute em outro terminal:
kubectl port-forward -n argocd svc/argocd-server 8080:443
Abra: https://localhost:8080 (usuário admin; consulte a senha no Secret argocd-initial-admin-secret)
EOF
