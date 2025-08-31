# Multi-Cloud Infrastructure as Code (IaC)

This repository contains Infrastructure as Code (IaC) configurations for deploying and managing resources across multiple cloud providers, including Google Cloud Platform (GCP), Amazon Web Services (AWS), and Cloudflare.

The project utilizes Terraform for infrastructure provisioning and Kubernetes (GKE) for container orchestration, along with various Kubernetes add-ons and configurations.

## Project Structure

The repository is organized by cloud provider and technology:

-   **`aws/`**: Terraform configurations for AWS resources.
    -   `terraform/`: Backend, budget alarms, secrets manager, and VPC configurations.
-   **`cloudflare/`**: Terraform configurations for Cloudflare resources.
    -   `terraform/`: Backend, tunnel, and variables definitions.
-   **`gcp/`**: Configurations and scripts specific to Google Cloud Platform.
    -   `GCE.md`: Documentation related to Google Compute Engine.
    -   `gce.py`: Python scripts for GCE.
    -   `k8s/`: Kubernetes manifests and Helm chart configurations for GKE.
        -   `argocd/`: ArgoCD image updater and repository secret.
        -   `bitnamicharts-oci.yml`: Bitnami charts OCI configuration.
        -   `cloudflare/`: Cloudflared and tunnel configurations.
        -   `dockerhub-auth.yml`: Docker Hub authentication secret.
        -   `external-dns/`: ExternalDNS API token secret and Cloudflare configuration.
        -   `external-secrets/`: External Secrets Helm chart.
        -   `grafana-cloud/`: Grafana Cloud Helm chart.
        -   `ingress-nginx/`: Ingress NGINX Helm chart.
    -   `terraform/`: Terraform configurations for GCP resources.
        -   `apis.tf`: GCP API enablement.
        -   `artifactory.tf`: Artifactory setup.
        -   `backend.tf`: Terraform backend configuration.
        -   `bucket.tf`: Cloud Storage bucket creation.
        -   `firewall.tf`: Network firewall rules.
        -   `gke.tf`: Google Kubernetes Engine cluster provisioning.
        -   `postgresVM.tf`: PostgreSQL VM instance.
        -   `secretsmanager.tf`: Secret Manager configurations.
        -   `variables.tf`: Terraform variable definitions.
        -   `vpc.tf`: Virtual Private Cloud network setup.
    -   `terraform_templates/`: Reusable Terraform templates.
        -   `cloud_run.tf`: Cloud Run service template.

## Technologies Used

-   **Terraform**: For declarative infrastructure provisioning.
-   **Kubernetes (GKE)**: For container orchestration on Google Cloud.
-   **Cloudflare**: For DNS management and network services.
-   **ArgoCD**: For GitOps-style continuous delivery to Kubernetes.
-   **ExternalDNS**: For synchronizing exposed Kubernetes services with DNS providers.
-   **External Secrets**: For integrating external secret management systems with Kubernetes.
-   **Grafana Cloud**: For monitoring and observability.
-   **NGINX Ingress Controller**: For managing external access to services in a Kubernetes cluster.

## Setup and Usage

Detailed instructions for setting up and using the infrastructure for each cloud provider can be found within their respective directories. Generally, the workflow involves:

1.  **Authentication**: Authenticate with the respective cloud provider (AWS, GCP, Cloudflare).
2.  **Terraform Initialization**: Navigate to the `terraform/` directory of the desired cloud provider and run `terraform init`.
3.  **Terraform Plan**: Review the planned changes using `terraform plan`.
4.  **Terraform Apply**: Apply the changes with `terraform apply`.
5.  **Kubernetes Deployment**: For GCP Kubernetes, apply the manifest files located in `gcp/k8s/` using `kubectl apply -f <file.yml>` or `helm upgrade --install`.

Please refer to the specific `README.md` files or documentation within each cloud provider's directory for more granular instructions.