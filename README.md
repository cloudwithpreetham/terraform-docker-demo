# Infrastructure as Code (IaC) with Terraform & Docker

Automated provisioning, configuration, state tracking, and lifecycle teardown of a containerized Nginx service using Terraform and the local Docker daemon.

---

## 📌 Project Overview

- **Objective:** Provision a local Docker container using Terraform (IaC).
- **Core Tools:** Terraform CLI (v1.5+), Docker Engine.
- **Provider:** `kreuzwerker/docker` (v4.6.0).
- **Target Application:** `nginx:latest` web server mapped to host port `8080`.
- **Deliverables:** `main.tf`, execution logs (`terraform-plan.log`, `terraform-apply.log`, `terraform-state.log`, `terraform-destroy.log`), and repository documentation.

---

## 🏗️ Architecture & IaC Workflow

```text
[ Developer / Terminal ]
         │
         │  1. terraform init
         ▼
[ Provider Initialization ] ──> Downloads kreuzwerker/docker plugin
         │
         │  2. terraform plan -out=tfplan
         ▼
[ Execution Graph & Plan ]  ──> Compares real state vs desired state
         │
         │  3. terraform apply tfplan
         ▼
[ Local Docker Daemon ]
         ├──> Pulls `nginx:latest` image
         └──> Spawns `terraform-docker-nginx` container (Port 8080:80)
         │
         ▼
[ State Management ]        ──> Records metadata in `terraform.tfstate`
         │
         │  4. terraform destroy
         ▼
[ Teardown & Cleanup ]      ──> Destroys container and removes managed resources
```

---

## 📁 Repository Structure

```text
terraform-docker-demo/
├── .gitignore               # Ignores .terraform/, *.tfstate, and temporary cache
├── docs/
│   └── screenshots/            # Optional: Screenshots of Nginx service running in browser
├── main.tf                  # Provider configuration, image, container, and outputs
├── terraform-plan.log       # Recorded dry-run execution plan output
├── terraform-apply.log      # Recorded provisioning log
├── terraform-state.log      # Output from terraform state list & show
├── terraform-destroy.log    # Recorded resource teardown output
└── README.md                # Project documentation and interview answers
```

---

## 🛠️ Step-by-Step Execution Workflow

### 1. Initialize Terraform Environment

Downloads and configures the required Docker provider plugin:

```bash
terraform init
```

### 2. Generate and Inspect the Execution Plan

Per assignment hints, generates a deterministic execution plan before applying changes:

```bash
terraform plan -out=tfplan | tee terraform-plan.log
```

### 3. Provision Infrastructure

Applies the plan to pull the Nginx image and run the container locally:

```bash
terraform apply tfplan | tee terraform-apply.log
```

### 4. Verify Provisioned Infrastructure & Inspect State

Per assignment hints, inspect the Terraform state file to verify tracked resources:

```bash
# List tracked resources
terraform state list | tee terraform-state.log

# Show container state attributes
terraform state show docker_container.nginx_container >> terraform-state.log

# Verify via Docker CLI and HTTP probe
docker ps --filter "name=terraform-docker-nginx"
curl -I http://localhost:8080
```

### 5. Destroy Infrastructure

Per assignment hints, tear down all provisioned resources to ensure clean lifecycle management:

```bash
terraform destroy -auto-approve | tee terraform-destroy.log
```

---

## 📄 Terraform Configuration (`main.tf`)

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "docker" {}

# Pull Docker Image
resource "docker_image" "nginx_image" {
  name         = "nginx:latest"
  keep_locally = false
}

# Provision Docker Container
resource "docker_container" "nginx_container" {
  name  = "terraform-docker-nginx"
  image = docker_image.nginx_image.image_id

  ports {
    internal = 80
    external = 8080
  }
}

# Outputs for Verification
output "nginx_container_id" {
  description = "ID of the deployed Docker container"
  value       = docker_container.nginx_container.id
}

output "nginx_container_name" {
  description = "Name of the Docker container"
  value       = docker_container.nginx_container.name
}

output "application_url" {
  description = "Access URL for Nginx"
  value       = "http://localhost:8080"
}
```

---

## 💡 Technical Interview Q&A (Task 3)

### 1. What is IaC?

Infrastructure as Code (IaC) is the management, provisioning, and configuration of IT infrastructure (compute instances, networks, storage, container clusters) through machine-readable definition files rather than manual point-and-click UI consoles or physical hardware configuration. IaC allows infrastructure to be version-controlled, automated, tested via CI/CD, and reliably duplicated across environments.

### 2. How does Terraform work?

Terraform uses a declarative syntax (HashiCorp Configuration Language — HCL) where engineers specify the target end-state:

1. **Init:** Discovers and downloads provider plugins needed for the target platform.
2. **Refresh & Plan:** Inspects the current state of infrastructure via provider APIs, matches it with the `.tfstate` file, calculates the difference against the `.tf` files, and generates a Directed Acyclic Graph (DAG) of changes.
3. **Apply:** Traverses the dependency graph and issues corresponding CRUD API calls to provision the resources.
4. **State Write:** Persists newly created resource IDs and metadata into the state file.

### 3. What is Terraform state file?

The `terraform.tfstate` file is a JSON document that maps configuration declarations to real-world infrastructure objects (e.g., mapping `resource "docker_container" "nginx_container"` to Docker Container ID `c5b6f87b6c6a...`). It tracks resource dependencies, attributes, and metadata. In production environments, state files are stored in remote backends (such as AWS S3 with DynamoDB state locking or Terraform Cloud) to allow safe team collaboration and prevent concurrent modifications.

### 4. Difference between `terraform plan` and `terraform apply`

- **`terraform plan`:** A non-destructive, read-only preview command. It assesses the existing state against the declared files and outputs the exact additions (`+`), changes (`~`), and destructions (`-`) that will occur without actually touching live infrastructure.
- **`terraform apply`:** The execution command. It executes the planned operations via platform APIs, provisions or updates infrastructure, and records the new reality into `terraform.tfstate`.

### 5. What are Terraform providers?

Providers are plugins that bridge Terraform core with target platforms, clouds, and APIs (such as Docker, AWS, GCP, Azure, Kubernetes, and Cloudflare). Providers translate standard Terraform resource blocks into target-specific API calls. They are managed under the `required_providers` block and downloaded during `terraform init`.

### 6. What is resource dependency?

Resource dependency defines the execution sequence Terraform follows when provisioning or destroying resources:

- **Implicit Dependency:** Formed automatically when a resource references an exported attribute of another resource (e.g., `image = docker_image.nginx_image.image_id`). Terraform automatically infers that the Docker image must be pulled before the container can be launched.
- **Explicit Dependency:** Declared manually using the `depends_on = [resource]` meta-argument when dependencies exist outside direct attribute references.

### 7. How do you handle secret variables?

- **Environment Variables:** Pass sensitive inputs via environment variables prefixed with `TF_VAR_<variable_name>` at runtime.
- **Sensitive Attribute Flag:** Mark input variables and outputs as `sensitive = true` to redact plaintext values from console outputs and CLI logs.
- **Secrets Managers:** Dynamically retrieve credentials at runtime from dedicated vaults (such as HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault) rather than hardcoding credentials.
- **Git Hygiene:** Add `*.tfvars`, `*.tfvars.json`, and `*.tfstate` to `.gitignore` to prevent credentials from being committed to source control.

### 8. Explain the benefits of Terraform

- **Multi-Cloud & Agnostic:** Provides a single, unified workflow across multiple cloud providers, on-premises systems, and SaaS platforms.
- **Declarative Paradigm:** Focuses on _what_ the infrastructure should look like rather than writing procedural scripts on _how_ to build it.
- **Drift Detection:** Compares real-world infrastructure against the state file to detect and rectify unauthorized manual modifications.
- **Execution Plans:** Offers dry-run previewing (`terraform plan`) to eliminate surprises and reduce downtime before executing changes.
- **Modularity & Reusability:** Facilitates reusable infrastructure blueprints through Terraform modules, standardizing enterprise architectural patterns.

Resource dependency defines the execution sequence Terraform follows when provisioning or destroying resources:

- **Implicit Dependency:** Formed automatically when a resource references an exported attribute of another resource (e.g., `image = docker_image.nginx_image.image_id`). Terraform automatically infers that the Docker image must be pulled before the container can be launched.
- **Explicit Dependency:** Declared manually using the `depends_on = [resource]` meta-argument when dependencies exist outside direct attribute references.

### 7. How do you handle secret variables?

- **Environment Variables:** Pass sensitive inputs via environment variables prefixed with `TF_VAR_<variable_name>` at runtime.
- **Sensitive Attribute Flag:** Mark input variables and outputs as `sensitive = true` to redact plaintext values from console outputs and CLI logs.
- **Secrets Managers:** Dynamically retrieve credentials at runtime from dedicated vaults (such as HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault) rather than hardcoding credentials.
- **Git Hygiene:** Add `*.tfvars`, `*.tfvars.json`, and `*.tfstate` to `.gitignore` to prevent credentials from being committed to source control.

### 8. Explain the benefits of Terraform

- **Multi-Cloud & Agnostic:** Provides a single, unified workflow across multiple cloud providers, on-premises systems, and SaaS platforms.
- **Declarative Paradigm:** Focuses on _what_ the infrastructure should look like rather than writing procedural scripts on _how_ to build it.
- **Drift Detection:** Compares real-world infrastructure against the state file to detect and rectify unauthorized manual modifications.
- **Execution Plans:** Offers dry-run previewing (`terraform plan`) to eliminate surprises and reduce downtime before executing changes.
- **Modularity & Reusability:** Facilitates reusable infrastructure blueprints through Terraform modules, standardizing enterprise architectural patterns.
