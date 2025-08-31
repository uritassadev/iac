# Google Cloud Platform (GCP) Lab 🚀
This repository contains Terraform configurations for managing and provisioning infrastructure on Google Cloud Platform (GCP), Includes Compute Engine, Artifact Registry, Storage Buckets, Networks, Firewalls, GKE and K8S manifest files tools and addons."

### GCP Resources

Here's a list of the modules included in this repository:

network: Creates a VPC network and subnets.

firewall: Configures firewall rules for a VPC network.

gke_cluster: Provisions a Google Kubernetes Engine (GKE) cluster.

google_container_registry: Creates a container registry.

### Installation

#### Terraform

Follow the official Terraform documentation to install Terraform on your system: [Install Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

#### Google Cloud SDK (gcloud)

Install the Google Cloud SDK to interact with GCP resources: [Install gcloud](https://cloud.google.com/sdk/docs/install)
```
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project uri-labs-465111
```

#### kubectl

kubectl is used to interact with Kubernetes clusters. If you're using GKE, it's often installed as part of the gcloud SDK. If not, you can install it separately: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

#### Connecting to GKE cluster

```
gcloud components install gke-gcloud-auth-plugin --quiet
gcloud container clusters get-credentials <GKE_CLUSTER_NAME> --zone <ZONE> --project <PROJETCT_ID>
```

### Github & GCP integration
#### Creating main WIF pool
```
gcloud iam workload-identity-pools create "cicd" --location=global --display-name="CI/CD Pool" --project="uri-labs-465111"
```

#### Manually enable "IAM Service Account Credentials API"
#### Creating Service account
```
gcloud iam service-accounts create "cicd-sa" --display-name="CICD service account" --project="uri-labs-465111"
gcloud projects add-iam-policy-binding "uri-labs-465111" \
    --member="serviceAccount:cicd-sa@uri-labs-465111.iam.gserviceaccount.com" \
    --role="roles/editor" \
    --project="uri-labs-465111"
```

#### Creating GitLab OIDC pool provider
```
gcloud iam workload-identity-pools providers create-oidc "gitlab" \
  --location="global" \
  --project="uri-labs-465111" \
  --workload-identity-pool="cicd" \
  --issuer-uri="https://auth.gcp.gitlab.com/oidc/uri-labs" \
  --display-name="GitLab" \
  --attribute-mapping="attribute.guest_access=assertion.guest_access,attribute.planner_access=assertion.planner_access,attribute.reporter_access=assertion.reporter_access,attribute.developer_access=assertion.developer_access,attribute.maintainer_access=assertion.maintainer_access,attribute.owner_access=assertion.owner_access,attribute.namespace_id=assertion.namespace_id,attribute.namespace_path=assertion.namespace_path,attribute.project_id=assertion.project_id,attribute.project_path=assertion.project_path,attribute.user_id=assertion.user_id,attribute.user_login=assertion.user_login,attribute.user_email=assertion.user_email,attribute.user_access_level=assertion.user_access_level,google.subject=assertion.sub"

```
```
# Grant the Artifact Registry Reader role to GitLab users with at least the Guest role
gcloud projects add-iam-policy-binding uri-labs-465111 \
  --member='principalSet://iam.googleapis.com/projects/427439741089/locations/global/workloadIdentityPools/cicd/attribute.guest_access/true' \
  --role='roles/artifactregistry.reader'

# Grant the Artifact Registry Writer role to GitLab users with at least the Developer role
gcloud projects add-iam-policy-binding uri-labs-465111 \
  --member='principalSet://iam.googleapis.com/projects/427439741089/locations/global/workloadIdentityPools/cicd/attribute.developer_access/true' \
  --role='roles/artifactregistry.writer'
```
#### Adding cicd service account artifactRegistry permissions
```
gcloud projects add-iam-policy-binding uri-labs-465111 \
  --member="serviceAccount:cicd-sa@uri-labs-465111.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer" \
  --condition=None
```
  
#### Creating Github OIDC pool provider
```
gcloud iam workload-identity-pools providers create-oidc "github" \
    --project="uri-labs-465111" \
    --location="global" \
    --workload-identity-pool="cicd" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --display-name="GitHub" \
    --attribute-mapping="google.subject=assertion.sub,\
attribute.actor=assertion.actor,\
attribute.repository=assertion.repository,\
attribute.ref=assertion.ref,\
attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="attribute.repository_owner == 'uri-labs'"
```

#### Creating Terraform cloud provider
```
gcloud iam workload-identity-pools providers create-oidc "terraform" \
  --location="global" \
  --workload-identity-pool="cicd" \
  --project="uri-labs-465111" \
  --display-name="TerraformCloud" \
  --issuer-uri="https://app.terraform.io" \
  --attribute-mapping="google.subject=assertion.sub,attribute.terraform_workspace_id=assertion.terraform_workspace_id,attribute.terraform_full_workspace=assertion.terraform_full_workspace" \
  --attribute-condition='assertion.terraform_organization_name=="uri-labs"'

```  

#### Creating Circle-CI provider

```
gcloud iam workload-identity-pools providers create-oidc "circle-ci" \
  --location="global" \
  --workload-identity-pool="cicd" \
  --project="uri-labs-465111" \
  --display-name="circle-ci" \
  --allowed-audiences "66f43140-bd8f-4b5a-8d8e-5483a8410c06" \
  --attribute-mapping google.subject=assertion.sub,attribute.audience=assertion.aud \
  --issuer-uri="https://oidc.circleci.com/org/66f43140-bd8f-4b5a-8d8e-5483a8410c06"

```  

#### binding service account with WIF pool   
```
gcloud iam service-accounts add-iam-policy-binding "cicd-sa@uri-labs-465111.iam.gserviceaccount.com" \
    --member="principalSet://iam.googleapis.com/projects/427439741089/locations/global/workloadIdentityPools/cicd/attribute.repository_owner/uri-labs" \
    --role="roles/iam.workloadIdentityUser" \
    --project="uri-labs-465111"
```