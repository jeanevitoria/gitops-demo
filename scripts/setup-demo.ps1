$ErrorActionPreference = 'Stop'

$wingetKind = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\kind.exe'
if (-not (Get-Command kind -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $wingetKind)) {
    $env:Path = "$(Split-Path -Parent $wingetKind);$env:Path"
}

foreach ($tool in @('docker', 'kubectl', 'kind')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Prerequisite missing: $tool. Install it and try again."
    }
}

$previousErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    docker info *> $null
    $dockerExitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($dockerExitCode -ne 0) {
    throw 'Docker is not running. Start Docker Desktop and try again.'
}

$clusterName = 'gitops-demo'
$clusters = @(kind get clusters)
if ($clusters -notcontains $clusterName) {
    kind create cluster --name $clusterName --wait 5m
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the kind cluster.' }
}

kubectl config use-context "kind-$clusterName"
if ($LASTEXITCODE -ne 0) { throw 'Could not select the Kubernetes context.' }
kubectl wait --for=condition=Ready node --all --timeout=180s
if ($LASTEXITCODE -ne 0) { throw 'The Kubernetes cluster is not ready yet.' }

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the argocd namespace.' }
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
if ($LASTEXITCODE -ne 0) { throw 'Could not install Argo CD.' }
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
if ($LASTEXITCODE -ne 0) { throw 'Argo CD server did not become ready before the timeout.' }

kubectl apply -f (Join-Path $PSScriptRoot '..\argocd-application.yaml')
if ($LASTEXITCODE -ne 0) { throw 'Could not register the GitOps application.' }

Write-Host ''
Write-Host 'Ambiente preparado. Aguarde a aplicacao ficar Synced e Healthy.'
Write-Host 'Em um terminal, execute: kubectl port-forward -n gitops-demo svc/gitops-demo 8081:80'
Write-Host 'Abra: http://localhost:8081'
Write-Host 'Para a interface Argo CD, execute em outro terminal:'
Write-Host 'kubectl port-forward -n argocd svc/argocd-server 8080:443'
Write-Host 'Abra: https://localhost:8080 (usuario admin; consulte a senha no Secret argocd-initial-admin-secret)'
