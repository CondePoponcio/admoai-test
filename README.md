# Task-API

A minimal Go “todo” service with in-memory persistence, Prometheus observability, and Docker-based deployment—either locally via Docker Compose or in the cloud via Fly.io + GitHub Actions.

---

## 🚀 Setup & Deploy

### Local (Docker Compose)

1. **Build & start**  
   From the repository root, run:
   ```bash
   docker-compose up --build


This will:

* Build the `task-api` service from `task-api/Dockerfile` and expose it on `localhost:8080`.
* Spin up Prometheus configured to scrape `/metrics` every 15 s on `localhost:9090` according to `prometheus.yml` .

2. **Inspect logs & health**

   ```bash
   docker-compose logs -f task-api
   ```

   Verify the HTTP server starts without errors and that Prometheus begins scraping metrics.

3. **Run the integration tests**

   ```bash
   cd task-api
   go test ./internal/task -v
   ```

   This script exercises all REST endpoints, checks success and error cases, and validates that `/metrics` is being populated.

---

### Cloud (Fly.io + GitHub Actions)

1. **`fly.toml` configuration**
   Ensure `task-api/fly.toml` contains your Fly app settings (ports, health checks, metrics) as shown here:

   ```toml
   app = "task-api"

   [build]
     dockerfile = "Dockerfile"

   [[services]]
     internal_port = 8080
     protocol      = "tcp"
     auto_cert     = true

     [[services.ports]]
       handlers = ["http"]
       port     = 80

     [[services.ports]]
       handlers = ["tls","http"]
       port     = 443

     [[services.tcp_checks]]
       interval     = "15s"
       timeout      = "2s"
       grace_period = "1m"

   [metrics]
     port = 8080
     path = "/metrics"
   ```



2. **GitHub Actions workflow**
   Pushing to `main` triggers the CI/CD pipeline defined in `.github/workflows/fly-deploy.yml`, which:

   * Runs unit tests (`go test ./internal/task`).
   * Installs `flyctl`, ensures the Fly app exists (creating it if necessary).
   * Deploys the container with `flyctl deploy --remote-only`.
     See the full workflow for details .

3. **Secrets & tokens**

   * Add your Fly.io deploy token as `FLY_API_TOKEN` in **GitHub → Settings → Secrets → Actions**.
   * The workflow reads `secrets.FLY_API_TOKEN` to authenticate and deploy.

4. **Monitor in Fly Dashboard**
   Fly.io will automatically scrape `/metrics` on port 8080. In the Fly Metrics UI you can visualize Go runtime stats and your custom metrics in real-time.

---

## 🏗️ Architecture Overview

* **Entry point**

  * `cmd/server/main.go`

    * Constructs a `mux.Router`, registers `/tasks` endpoints, and wires up `/metrics`.
    * Configures an `http.Server` with sensible timeouts (`ReadHeaderTimeout`, `IdleTimeout`).

* **Domain logic**

  * `internal/task/service.go`

    * In-memory store protected by `sync.RWMutex`, generates UUIDs, handles state transitions (`pending` → `completed`).
  * `internal/task/handler.go`

    * Decodes JSON payloads, enforces required fields, serializes responses, and returns appropriate HTTP status codes.

* **Observability**

  * `pkg/metrics/prometheus.go`

    * Exposes `/metrics` via `promhttp.Handler()`.
    * Automatically includes Go runtime and process metrics (heap, GC, goroutines, CPU, etc.).

* **Containerization & orchestration**

  * **Dockerfile** (multi-stage build with Go 1.24.2 → Alpine).
  * **Docker Compose** wiring `task-api` and `prometheus`.

* **CI/CD**

  * **GitHub Actions**: test → build → remote Fly.io deploy.
  * **Fly.io**: remote image builds, health checks, TLS via `auto_cert`, metrics scraping.

* **Cloud Infrastructure (Fly.io)**

  * **CI/CD Pipeline**
    Your GitHub Actions workflow uses the `superfly/flyctl-actions/setup-flyctl` action to authenticate (`FLY_API_TOKEN`), run tests, and then invoke `flyctl deploy --remote-only`. Under the hood, that command spins up a remote builder on Fly, builds your container image there, and runs the deployment steps — all without needing Docker installed locally.
  * **Artifact Repository (Fly Registry)**
    Fly provides a private container registry at `registry.fly.io/<app-name>`. In CI you run `fly auth docker` (via the Fly CLI) to configure Docker credentials, then you can push images with:

    ```bash
    docker push registry.fly.io/${{ env.FLY_APP }}:${{ github.sha }}
    ```

    or let `flyctl deploy` push the image automatically for you ([Fly.io][3], [Fly.io][4]).
  * **PaaS Service Deployment**
    When you run `flyctl deploy --app $FLY_APP --region $FLY_REGION`, Fly’s orchestrator:

    1. Fetches (or builds) the container image from the Fly Registry
    2. Schedules it onto a Firecracker microVM in the specified region
    3. Performs health checks, TLS termination (`auto_cert`), and attaches your configured metrics scraping
    4. Opens the app on Fly’s global anycast network, auto-scales based on load, and scrapes your `/metrics` endpoint alongside system metrics.


---

## ⚖️ Trade-offs & Future Improvements

| Concern           | Current                         | What to Improve with More Time             |
| ----------------- | ------------------------------- | ------------------------------------------ |
| **Persistence**   | In-memory only (volatile)       | Add SQLite or PostgreSQL with migrations   |
| **Observability** | `/metrics` scrape of runtime    | Structured logs, OpenTelemetry tracing     |
| **Scalability**   | Single instance per environment | Autoscale on Fly.io or migrate to k8s      |
| **Security**      | Open API (no auth)              | Add JWT/OAuth2, rate limiting, RBAC        |
| **Deployment**    | Fly.io only                     | Introduce Terraform/IaC, multi-env support |
| **Alerting**      | None                            | Define Prometheus/Grafana alert rules      |

Architecture design with more time:


Here’s how I would have laid out a fully-fledged, professional AWS-Kubernetes architecture using Terraform—in a `terraform-best-solution/` folder—so you can review the modules without having to validate them all right now. Once you `terraform apply` it, you spin up ArgoCD on EKS (and its Image Updater), and your GitHub Action (shown below) will push new images to ECR and ArgoCD will deploy them in real time.

```text
terraform-best-solution/
├── provider.tf          # AWS, Kubernetes & Helm providers
├── variables.tf         # Input variables (cluster_name, VPC CIDR, etc.)
├── terraform.tfvars     # dev values (us-west-2, subnets, node sizes…)
├── vpc.tf               # VPC with 2 public & 2 private subnets, IGW, NAT gateways, route tables
├── iam.tf               # 
│   • EKS cluster IAM role
│   • EKS node IAM role (with AmazonEKSWorkerNodePolicy, etc.)
│   • OIDC providers for EKS & GitHub
│   • GitHub Actions role (trusts GitHub OIDC; perms for ECR and EKS)
│   • IRSA role for ArgoCD Image Updater (serviceAccount argocd-image-updater)
├── ecr.tf               # Private ECR repo with scan-on-push
├── eks.tf               # 
│   • aws_eks_cluster (version 1.32) in those subnets
│   • aws_eks_node_group (t3.medium, autoscaling 1–2 nodes)
├── helm.tf              # Helm release of ArgoCD (chart v5.3.6) into EKS
│                         with image-updater SA annotated for IRSA
└── outputs.tf           #
    • cluster_endpoint, cluster_ca, kubeconfig  
    • ecr_repository_url  
    • argocd_image_updater_role_arn  
    • eks_oidc_provider_arn, github_oidc_provider_arn  
```

**Workflow once you’ve applied Terraform**

1. **Retrieve outputs**

   ```bash
   cd terraform-best-solution
   terraform init
   terraform apply -auto-approve
   ```
2. **Configure your GitHub Action** to consume the ECR URL and AWS region from Terraform outputs (e.g. via `$GITHUB_ENV` or Action outputs).
3. **Push your Docker image** to ECR using this job:

```yaml
name: Build and Push to ECR

on:
  push:
    branches: [ main ]

permissions:
  id-token: write      # necessary for OIDC
  contents: read

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY_URL }} # could come from terraform output

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region:    ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region ${{ env.AWS_REGION }} \
            | docker login \
                --username AWS \
                --password-stdin ${{ env.ECR_REPOSITORY }}

      - name: Build, tag and push Docker image
        run: |
          IMAGE_TAG=${GITHUB_SHA::8}
          docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
          docker push        $ECR_REPOSITORY:$IMAGE_TAG

      - name: Tag latest and push
        run: |
          IMAGE_TAG=${GITHUB_SHA::8}
          docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REPOSITORY:latest
          docker push $ECR_REPOSITORY:latest
```

With this in place:

* **ArgoCD** (deployed via `helm.tf`) watches your Git repo and syncs into EKS.
* **Image Updater** automatically bumps Kubernetes manifests when a new tag lands in ECR.
* **GitHub Actions** handles the CI part (build & push), using Terraform’s outputs to wire everything together.

> **Note:** I haven’t had time to fully validate every module and setting the argocd with the repo, but the complete Terraform code lives in `terraform-best-solution/`. Once you apply it, ArgoCD on EKS will pick up changes in real time after configured the repo, giving you a true GitOps-powered, enterprise-grade pipeline. I ran out of time to configure Prometheus and Grafana for a better alert system, so in the end I went with Fly.io since it was faster and less risky in case something went wrong when connecting the components. But at least the .tf files that were left are valid and work successfully. Then I would only have to forward to the argocd mounted on the EKS and configure the repo, which can also be done in an argocd application yaml, but I was running out of time.



---

## 🧪 How to Test Locally

1. **Unit tests**

   ```bash
   cd task-api
   go test ./internal/task -v
   ```

2. **Manual endpoint checks**

   ```bash
   # Create tasks
   curl -X POST -H "Content-Type: application/json" \
     -d '{"title":"Fix deploy","priority":"high"}' localhost:8080/tasks

   # Fetch by ID
   curl localhost:8080/tasks/<id>

   # Complete task
   curl -X POST localhost:8080/tasks/<id>/complete

   # List by status
   curl localhost:8080/tasks?status=pending
   ```

4. **Prometheus queries**
   Once Prometheus is up on `http://localhost:9090`, try:

   ```promql
   # 1. Number of active goroutines
    go_goroutines

    # 2. CPU consumed by your process (core-seconds per second)
    rate(process_cpu_seconds_total[5m])

    # 3. Resident memory (RSS) in bytes
    process_resident_memory_bytes

    # 4. Total virtual memory allocated in bytes
    process_virtual_memory_bytes

    # 5. Heap memory currently in use in bytes
    go_memstats_heap_alloc_bytes

   ```

These will help you validate both your Go runtime health and the responsiveness of your metrics endpoint.

---

