$ErrorActionPreference = 'Stop'

foreach ($tool in @('docker', 'kubectl', 'kind')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Pré-requisito ausente: $tool. Instale-o e tente novamente."
    }
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker não está ativo. Inicie o Docker Desktop e tente novamente.'
}

$clusterName = 'gitops-demo'
$clusters = @(kind get clusters)
if ($clusters -notcontains $clusterName) {
    kind create cluster --name $clusterName --wait 5m
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível criar o cluster kind.' }
}

kubectl config use-context "kind-$clusterName"
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível selecionar o contexto Kubernetes.' }
kubectl wait --for=condition=Ready node --all --timeout=180s
if ($LASTEXITCODE -ne 0) { throw 'O cluster Kubernetes ainda não está pronto.' }

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível preparar o namespace argocd.' }
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível instalar o Argo CD.' }
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
if ($LASTEXITCODE -ne 0) { throw 'O servidor Argo CD não ficou pronto no prazo.' }

kubectl apply -f (Join-Path $PSScriptRoot '..\argocd-application.yaml')
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível cadastrar a aplicação GitOps.' }

Write-Host ''
Write-Host 'Ambiente preparado. Aguarde a aplicação ficar Synced e Healthy.'
Write-Host 'Em um terminal, execute: kubectl port-forward -n gitops-demo svc/gitops-demo 8081:80'
Write-Host 'Abra: http://localhost:8081'
Write-Host 'Para a interface Argo CD, execute em outro terminal:'
Write-Host 'kubectl port-forward -n argocd svc/argocd-server 8080:443'
Write-Host 'Abra: https://localhost:8080 (usuário admin; consulte a senha no Secret argocd-initial-admin-secret)'
