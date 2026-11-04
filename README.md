# Demonstração de GitOps com Argo CD

Esta demo mostra o Argo CD acompanhando os manifestos Kubernetes neste repositório. O navegador exibe uma página própria servida pelo Nginx, e a mudança ao vivo escala o Deployment de 2 para 4 réplicas após um commit e push.

## Arquivos

- `index.html`: página exibida no navegador.
- `kubernetes/configmap.yaml`: disponibiliza o HTML ao Nginx.
- `kubernetes/deployment.yaml` e `kubernetes/service.yaml`: aplicação web no Kubernetes, inicialmente com 2 réplicas.
- `argocd-application.yaml`: Application que acompanha a pasta `kubernetes/` na branch `main`.

## Configurar o repositório

O manifesto Argo CD já aponta para `https://github.com/jeanevitoria/gitops-demo.git`. Envie os arquivos para a branch `main` para que o Argo CD possa lê-los.

## Preparação automática

Envie os arquivos deste repositório para a branch `main` antes de iniciar. A máquina precisa ter Docker ativo, `kubectl` e `kind` instalados. O script cria um cluster local chamado `gitops-demo`, instala o Argo CD e cadastra a aplicação. Se esse cluster já existir, ele será reutilizado.

No Windows PowerShell:

```powershell
.\scripts\setup-demo.ps1
```

No Linux ou macOS:

```bash
chmod +x scripts/setup-demo.sh
./scripts/setup-demo.sh
```

Os scripts verificam os pré-requisitos, iniciam o cluster kind, instalam o Argo CD e cadastram a Application. A primeira sincronização pode levar alguns minutos; confira se a aplicação chegou a `Synced` e `Healthy`.

## Ver a aplicação e o Argo CD

Depois do setup, mantenha os encaminhamentos rodando em dois terminais:

```powershell
kubectl port-forward -n gitops-demo svc/gitops-demo 8081:80
```

```powershell
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Abra [http://localhost:8081](http://localhost:8081) para a página e [https://localhost:8080](https://localhost:8080) para a interface Argo CD. No login, o usuário inicial é `admin`; obtenha a senha no Secret `argocd-initial-admin-secret`.

## Demonstração ao vivo

1. Confirme que a aplicação está `Synced` e `Healthy` no Argo CD e que o Deployment tem 2 réplicas prontas.
2. Em outro terminal, acompanhe a implantação:

   ```powershell
   kubectl get deployment gitops-demo -n gitops-demo -w
   ```

3. Mude `replicas: 2` para `replicas: 4` em `kubernetes/deployment.yaml`.
4. Faça commit e push:

   ```powershell
   git add kubernetes/deployment.yaml
   git commit -m "demo: scale replicas to 4"
   git push origin main
   ```

5. Mostre o Argo CD sincronizando e o Deployment convergindo para `4/4`.

Para preparar uma nova apresentação, restaure `replicas: 2`, faça commit e push e aguarde o cluster voltar a `2/2`.
