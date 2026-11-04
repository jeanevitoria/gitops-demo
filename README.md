# Demonstração de GitOps com Argo CD

Esta demo mostra o Argo CD acompanhando os manifestos Kubernetes neste repositório. O navegador exibe uma página servida pelo Nginx. Na apresentação, altere o Deployment de 2 para 4 réplicas, faça commit e push e observe o Argo CD sincronizar o cluster.

## Estrutura

- `index.html`: página da aplicação.
- `kubernetes/configmap.yaml`: disponibiliza o HTML para o Nginx.
- `kubernetes/deployment.yaml`: Deployment, inicialmente com 2 réplicas.
- `kubernetes/service.yaml`: Service da aplicação.
- `argocd-application.yaml`: Application que acompanha `kubernetes/` na branch `main`.
- `scripts/setup-demo.ps1` e `scripts/setup-demo.sh`: preparação automática para Windows e Linux/macOS.

## O que precisa estar instalado

Você precisa de Docker com o mecanismo Linux ativo, `kubectl` e `kind`. O script cria o cluster Kubernetes local com kind, instala o Argo CD e cadastra a aplicação. Ele não instala Docker, kubectl ou kind.

## Clonar o repositório

O repositório da demo já está publicado. Cada integrante deve clonar a branch `main` e executar os comandos a partir da pasta clonada:

```bash
git clone https://github.com/jeanevitoria/gitops-demo.git
cd gitops-demo
```

### Windows

1. No PowerShell, verifique o que já está instalado:

   ```powershell
   kubectl version --client
   kind version
   docker --version
   ```

2. Instale somente as ferramentas cujo comando não foi reconhecido:

   ```powershell
   # Execute somente se kubectl version --client indicou comando ausente
   winget install -e --id Kubernetes.kubectl

   # Execute somente se kind version indicou comando ausente
   winget install Kubernetes.kind
   ```

   Se Docker não estiver instalado, baixe [Docker Desktop para Windows](https://docs.docker.com/desktop/setup/install/windows-install/) e inicie-o com o mecanismo Linux/WSL 2.

3. Feche e reabra o PowerShell se instalou alguma ferramenta. Confirme novamente as versões e que o daemon Docker está ativo:

   ```powershell
   kubectl version --client
   kind version
   docker --version
   docker info
   ```

   `docker info` deve mostrar as seções `Client` e `Server`, e `OSType: linux`. Se o cliente estiver instalado mas o servidor não responder, inicie o Docker Desktop.

### Linux

Primeiro confira quais ferramentas já estão instaladas:

```bash
kubectl version --client
kind version
docker --version
```

Instale apenas o que estiver faltando. Para outras distribuições além de Ubuntu/Debian, siga as instruções oficiais do [Docker Engine](https://docs.docker.com/engine/install/) e do [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/).

1. Se Docker não estiver instalado, use o [guia oficial para Ubuntu](https://docs.docker.com/engine/install/ubuntu/). Inicie o daemon e confirme que `docker info` mostra as seções Client e Server. Se o Docker exigir `sudo`, configure o acesso do seu usuário seguindo os [passos pós-instalação oficiais](https://docs.docker.com/engine/install/linux-postinstall/); depois, saia e entre novamente na sessão.
2. Se `kubectl version --client` falhar por comando ausente, instale `kubectl` (a arquitetura comum de PCs é `amd64`; em ARM64, substitua `amd64` por `arm64` nos dois caminhos):

   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   rm kubectl
   ```

3. Se `kind version` falhar por comando ausente, instale kind (para ARM64, use `kind-linux-arm64`):

   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
   chmod +x ./kind
   sudo install -o root -g root -m 0755 ./kind /usr/local/bin/kind
   rm ./kind
   ```

4. Abra um novo terminal se instalou alguma ferramenta e verifique tudo novamente:

   ```bash
   kubectl version --client
   kind version
   docker info
   ```

   O `docker info` deve mostrar detalhes do servidor. Se o comando só funcionar com `sudo`, ajuste as permissões conforme a documentação de pós-instalação do Docker antes de rodar o script.

## Executar a preparação automática

Abra PowerShell no Windows ou um terminal Bash no Linux/macOS dentro da pasta `gitops-demo` que acabou de clonar e rode o script correspondente. O manifesto Argo CD já aponta para `https://github.com/jeanevitoria/gitops-demo.git`, branch `main`; para outro fork, atualize `repoURL` e `targetRevision` em `argocd-application.yaml` antes de executar o script.

Windows PowerShell:

```powershell
.\scripts\setup-demo.ps1
```

Se o PowerShell bloquear a execução do script, execute somente para esse processo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-demo.ps1
```

Linux/macOS:

```bash
chmod +x scripts/setup-demo.sh
./scripts/setup-demo.sh
```

O script cria ou reutiliza o cluster kind `gitops-demo`, seleciona o contexto `kind-gitops-demo`, instala o Argo CD e cadastra a Application. A instalação usa server-side apply para acomodar o tamanho das CRDs do Argo CD.

Confira o estado da aplicação:

```bash
kubectl get application gitops-demo -n argocd
kubectl get deployment,pods,service -n gitops-demo
```

Aguarde o Argo CD mostrar `Synced` e `Healthy`. A primeira leitura do Git pode levar alguns minutos. Se o Application mostrar erro de repositório ou caminho, confirme que o push para `main` terminou e que o repositório é público.

## Abrir a página e o Argo CD

Deixe cada comando abaixo rodando em um terminal separado. Não feche esses terminais durante a demonstração.

Terminal 1, encaminha a aplicação web:

```bash
kubectl port-forward -n gitops-demo svc/gitops-demo 8081:80
```

Abra [http://localhost:8081](http://localhost:8081).

Terminal 2, encaminha a interface do Argo CD:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Abra [https://localhost:8080](https://localhost:8080). O usuário inicial é `admin`. O navegador pode avisar que o certificado é local; isso é esperado nesse encaminhamento local.

### Consultar a senha inicial do admin

PowerShell:

```powershell
$senhaBase64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($senhaBase64))
```

Linux/macOS:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

Digite a senha no login da interface Argo CD. Não a publique no Git nem a inclua em capturas de tela.

## Demonstração ao vivo

1. Confirme na interface Argo CD que `gitops-demo` está `Synced` e `Healthy`, e mostre o Deployment com 2 réplicas prontas.
2. Em outro terminal, acompanhe a mudança:

   ```bash
   kubectl get deployment gitops-demo -n gitops-demo -w
   ```

3. Edite `kubernetes/deployment.yaml`, mudando `replicas: 2` para `replicas: 4`.
4. Faça commit e push:

   ```bash
   git add kubernetes/deployment.yaml
   git commit -m "demo: scale replicas to 4"
   git push origin main
   ```

5. Mostre o Argo CD sincronizando e o Deployment convergindo para `4/4`. Se a atualização demorar, use `Refresh` na interface Argo CD.

Para repetir a apresentação, restaure `replicas: 2`, faça commit e push e aguarde o Deployment voltar a `2/2`.

## Encerrar e remover o cluster local

Para apenas interromper os encaminhamentos, use `Ctrl+C` nos terminais correspondentes. Os recursos continuam no cluster. Para excluir o cluster local e todos os recursos dessa demo:

```bash
kind delete cluster --name gitops-demo
```

Isso apaga o cluster local `gitops-demo`; não apaga o repositório GitHub.

## Referências oficiais

- [Instalar kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Instalar kubectl no Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
- [Instalar kubectl no Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Instalar Docker Desktop no Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
- [Instalar Docker Engine no Linux](https://docs.docker.com/engine/install/)
- [Guia inicial do Argo CD](https://argo-cd.readthedocs.io/en/latest/getting_started/)
