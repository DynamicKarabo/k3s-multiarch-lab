# K3s Multi-Arch Lab 🚀

**A heterogeneous multi-node Kubernetes cluster spanning x86 and ARM across two continents — with full GitOps, IaC, and a local dev loop.**

```
┌─────────────────────────────────────────────────────────────────┐
│                        k3s-multiarch-lab                        │
│                                                                 │
│   ┌─────────────────────┐      ┌───────────────────────────┐   │
│   │  Hetzner VPS (DE)   │      │  Oracle Cloud (ZA)        │   │
│   │  x86_64 · 4 vCPU    │◄────►│  Ampere A1 ARM · 4 OCPU  │   │
│   │  8GB RAM · €9/mo    │  TS  │  24GB RAM · FREE          │   │
│   │  K3s Server+Worker  │      │  K3s Agent (Worker)       │   │
│   └──────────┬──────────┘      └──────────────┬────────────┘   │
│              │                                 │               │
│         ┌────┴────┐                       ┌───┴────┐          │
│         │ Postgres│                       │Inference│          │
│         │ Redis   │                       │(ML)     │          │
│         │ Web     │                       │         │          │
│         └─────────┘                       └─────────┘          │
│                                                                 │
│   Workload placement driven by hardware specialization,         │
│   not redundancy. Stateful → low-latency SSD (Hetzner).         │
│   Memory-heavy → big ARM RAM (Oracle).                          │
└─────────────────────────────────────────────────────────────────┘
```

## Why This Exists

Most Kubernetes portfolios show the same "deploy a web app" pattern. This one demonstrates:

- **Cross-architecture orchestration** — x86 (Intel) and ARM (Ampere) nodes in one cluster
- **Cross-continent networking** — Germany ↔ South Africa, Tailscale encrypted mesh
- **Multi-architecture container images** — Docker Buildx + GHCR manifest lists
- **Environment-portable IaC** — same Ansible roles target local k3d and production nodes
- **GitOps deployment pipeline** — GitHub Actions → GHCR → Argo CD/Flux
- **Infrastructure-as-Code** — Terraform provisioning Oracle Cloud ARM instances

## Architecture

### Cluster Topology

| Node | Host | Arch | Role | Spec | Cost |
|------|------|------|------|------|------|
| `hermes` | Hetzner (Falkenstein, DE) | `amd64` | Server + Worker | 4 vCPU, 8GB RAM | ~€9/mo |
| `oracle-arm` | Oracle (Johannesburg, ZA) | `arm64` | Agent (Worker) | 4 OCPU, 24GB RAM | Free |
| `local-dev` | Your machine (Pop!_OS) | `amd64` | k3d (3 nodes) | shared host resources | $0 |

### Networking

```
[Your Machine] ─── k3d ─── [localhost:8080]
     │
     │ (SSH + Ansible)
     ▼
[Hetzner VPS] ── Tailscale ── [Oracle ARM]
     10.0.0.1        │           10.0.0.2
     ──────── 170ms RTT ──────────>
```

- **Tailscale** (WireGuard-based) encrypts all cross-node traffic
- K3s Flannel bound to `tailscale0` — pods communicate over the encrypted mesh
- k3d on local machine — fast iteration, destroyed/recreated in seconds

### Workload Scheduling

```
                 ┌──────────────────┐
                 │  Ingress (Hetzner)│  ← Cloudflare Tunnel or Tailscale Funnel
                 └────────┬─────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────▼──────┐ ┌─────▼──────┐ ┌──────▼──────────┐
   │  API Gateway │ │  Postgres  │ │  Redis Cache    │
   │  (Hetzner)   │ │ (Hetzner)  │ │  (Hetzner)      │
   └──────────────┘ └────────────┘ └─────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  ML Inference Pod   │
                    │  (Oracle ARM)       │  ← nodeSelector: node-type=arm64
                    └─────────────────────┘
```

**Scheduling decisions are deliberate:**
- **Postgres + Redis** → Hetzner (fast local SSD, low-latency for the web tier)
- **ML inference** → Oracle ARM (24GB RAM, free compute, memory-intensive)
- **Node labels + taints** encode these decisions — not hardcoded IPs

## Repository Structure

```
k3s-multiarch-lab/
├── clusters/                    # Kubernetes manifests (Kustomize)
│   ├── base/                    #   Shared resources
│   └── overlays/               #   Environment overrides
│       ├── local/              #     k3d (NodePort, low resources)
│       └── prod/               #     Prod (Ingress, TLS, multi-arch)
├── infra/
│   ├── ansible/                # Configuration management
│   │   ├── inventories/        #   Local + prod inventory definitions
│   │   ├── group_vars/         #   Environment variables
│   │   └── roles/              #   common, tailscale, k3s-server, k3s-agent
│   └── terraform/              # Infrastructure provisioning
│       ├── modules/
│       │   └── oci-instance/   #   Reusable OCI compute module
│       └── envs/
│           └── oracle/         #   OCI ARM instance (Terraform + cloud-init)
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

| Tool | Version | Why |
|------|---------|-----|
| [k3d](https://k3d.io) | ≥5.x | Local K3s cluster (containers) |
| [Terraform](https://terraform.io) | ≥1.5 | Oracle cloud provisioning |
| [Ansible](https://ansible.com) | ≥9.x | Configuration management |
| [Docker](https://docker.com) | ≥24 | Container runtime |
| [kubectl](https://kubernetes.io) | ≥1.28 | Cluster management |

### 1. Local Cluster (Development)

```bash
# Create 3-node cluster (1 server + 2 agents)
k3d cluster create multiarch-lab \
  --servers 1 --agents 2 \
  --port "8080:80@loadbalancer"

# Verify
kubectl get nodes
kubectl get pods -A

# Test Kustomize deployment
kubectl apply -k clusters/overlays/local/

# Tear down
k3d cluster delete multiarch-lab
```

### 2. Production Cluster — Hetzner VPS (Server + Worker)

```bash
# Configure the VPS using Ansible
cd infra/ansible
ansible-playbook site.yml -i inventories/prod/ --limit k3s_server

# Get the join token
k3s kubectl get nodes
cat /var/lib/rancher/k3s/server/node-token  # → save for Oracle setup
```

### 3. Production Cluster — Oracle ARM (Agent)

```bash
# Provision Oracle ARM instance
cd infra/terraform/envs/oracle
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply

# The instance auto-joins the cluster via cloud-init
# Verify on the Hetzner server
k3s kubectl get nodes -o wide
```

### 4. Deploy

```bash
# Apply production manifests
kubectl apply -k clusters/overlays/prod/
```

## CI/CD Pipeline

```
Git Push ──► GitHub Actions ──► Buildx (multi-arch) ──► GHCR
                │                                        │
                ▼                                        ▼
         Test + Lint                              Push image tag
                │                                        │
                └──────────────┬─────────────────────────┘
                               ▼
                    GitOps Repo (image bump)
                               │
                    Argo CD / Flux ──► K3s Cluster
```

### Multi-Architecture Images

```yaml
# GitHub Actions workflow snippet
- uses: docker/setup-qemu-action@v3
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v6
  with:
    platforms: linux/amd64,linux/arm64
    push: true
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Key Design Decisions

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| **Cluster** | K3s | Full K8s APIs, low resource footprint (~512MB), single binary |
| **Local dev** | k3d | Instant cluster, same manifests target prod, no VM overhead |
| **Networking** | Tailscale | Free tier, NAT traversal, encrypted mesh, industry standard |
| **Multi-arch** | Buildx + QEMU | Single workflow, GHCR manifest lists, native ARM runners possible |
| **Provisioning** | Terraform + cloud-init | Reusable IaC, zero-click node bootstrap |
| **Config mgmt** | Ansible | Same roles for local and prod, idempotent, agentless |
| **GitOps** | Argo CD / Flux | Portfolio-significant, audit trail, declarative ops |
| **Storage** | Local-path + PVC | Skip distributed storage across continents, backup to OCI Object Storage |

## What's Deliberately Skipped

- **Service mesh** — pure theater at 2-node scale
- **Multi-master HA** — impossible across 170ms WAN, don't fake it
- **Distributed storage** — Longhorn on a 170ms link = pain, pain, pain
- **The Hard Way** — K3s is the right abstraction; from-scratch K8s adds no signal

## Portfolio Narrative

> "I built a heterogeneous multi-node Kubernetes cluster spanning x86 and ARM infrastructure across two continents. The cluster uses K3s for lightweight Kubernetes orchestration, Tailscale for encrypted cross-DC networking, and Terraform + cloud-init for reproducible provisioning. Workload placement is driven by hardware specialization — stateful services run on the low-latency Hetzner SSD node while memory-intensive inference workloads exploit the 24GB free ARM tier in Oracle Cloud. A local k3d dev environment provides sub-second iteration, graduating the same Ansible-managed configuration to production. The full pipeline uses multi-architecture Docker builds (Buildx + GHCR) and GitOps deployment (Argo CD/Flux)."

## License

MIT
