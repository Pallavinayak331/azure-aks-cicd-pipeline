# Full Build Walkthrough

## 1–6. Infrastructure

Provisioned via the Azure Portal:

- **Resource Group** `DevEnvironment-RG` (Region: West US)
- **VNet** `Dev-VNet`, address space `10.0.0.0/25` (128 addresses)
- **Subnet** `Dev-Subnet`, `10.0.0.0/26` (64 addresses)
- **Storage Account** `devstorage54321`, Standard_LRS, with a private
  container `football-images` (anonymous access disabled; access restricted
  to a specific IP)
- **NSG** `Dev-NSG` with two inbound rules:
  - `Allow-HTTP` — TCP 80, priority 100
  - `Allow-SSH` — TCP 22, priority 110
- **VM** `Dev-VM` — Ubuntu Server 24.04 LTS, trusted launch, secure boot + vTPM enabled

## 7–8. VM provisioning

SSH'd into the VM and installed:

\`\`\`bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker azure-dev-user

sudo apt install -y git
\`\`\`

## 9–11. App containerization

\`\`\`bash
mkdir hello-world-app && cd hello-world-app
touch index.html   # content in app/index.html of this repo
vi Dockerfile        # content in app/Dockerfile of this repo

sudo docker build -t hello-world-app .
sudo docker run -p 80:80 hello-world-app   # verified locally before pushing
\`\`\`

## 12–13. AKS + ACR

\`\`\`bash
az aks create \
  --resource-group DevEnvironment-RG \
  --name Dev-AKS \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --generate-ssh-keys

az acr create \
  --resource-group DevEnvironment-RG \
  --name devacr54321 \
  --sku Basic

az acr login --name devacr54321
docker tag hello-world-app devacr54321.azurecr.io/hello-world-app:latest
docker push devacr54321.azurecr.io/hello-world-app:latest

az aks update \
  --resource-group DevEnvironment-RG \
  --name Dev-AKS \
  --attach-acr devacr54321

az aks get-credentials --resource-group DevEnvironment-RG --name Dev-AKS
kubectl apply -f k8s/deployment.yaml
\`\`\`

## Azure DevOps CI/CD Pipeline

**Project:** `pipeline1234` (Azure DevOps organization)
**Repo:** `Dev-Repo` — contains `Dockerfile`, `index.html`, `Deployment.yaml`, `script.ps1`

### CI: Build Pipeline (`CI-HelloWorld-App`) — Classic Editor

| Task | Type | Script |
|------|------|--------|
| Get sources | Clone repo | `Dev-Repo`, `master` branch |
| Build Docker Image | Command line | `docker build -t hello-world-app .` |
| Tag Docker Image | Command line | `docker tag hello-world-app devacr54321.azurecr.io/hello-world-app:$(Build.BuildId)` |
| Push Docker Image | Command line | `az acr login --name devacr54321`<br>`docker push devacr54321.azurecr.io/hello-world-app:$(Build.BuildId)` |
| Creating metadata | Command line | `cp deployment.yaml $(Build.ArtifactStagingDirectory)/`<br>`cp script.ps1 $(Build.ArtifactStagingDirectory)/` |
| Publish Artifact: drop | Publish build artifacts | Path: `$(Build.ArtifactStagingDirectory)` |

### CD: Release Pipeline — two stages

**Stage 1 — Deploy**
- Artifact source: `CI-HelloWorld-App` (Continuous Deployment trigger enabled)
- Task: **Deploy to Kubernetes** (Kubernetes Service Connection, Azure Subscription auth)
  - Manifest: `$(System.DefaultWorkingDirectory)/_CI-HelloWorld-App/drop/Deployment.yaml`

**Stage 2 — Health check**
- Task: **PowerShell**
  - Script path: `$(System.DefaultWorkingDirectory)/_CI-HelloWorld-App/drop/script.ps1`
- PowerShell was installed on the agent VM (`Dev-VM`, self-hosted agent) via:
  \`\`\`bash
  wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y powershell
  \`\`\`
- `kubectl` was installed the same way (`sudo snap install kubectl --classic`)
  and the agent authenticated to the cluster via `az aks get-credentials`

Both stages succeeded end-to-end (see `docs/screenshots/` for the run logs).

## Exposing the app externally

The original `Deployment.yaml` alone wasn't reachable from outside the
cluster, so a `Service` of type `LoadBalancer` was added and applied directly:

\`\`\`bash
kubectl apply -f service.yaml
kubectl get svc
# hello-world-service   LoadBalancer   10.0.70.8   20.66.52.39   80:31289/TCP
\`\`\`

Visiting the external IP in a browser confirmed the deployed app was live and
serving the "Hello, World!" page.

## Azure Boards

- Process: **Inherited Agile**
- Custom rule on the **User Story** work item type: when a work item is
  created, automatically set **Assigned To** to the current user
- Two sprints created, 2-week duration each (`Sprint 1`: 19/11–03/12,
  `Sprint 2`: 04/12–18/12)
- Verified: creating a new User Story auto-assigned it to its creator
