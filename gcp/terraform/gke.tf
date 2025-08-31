###################################################
############## GKE Service Account ################
###################################################

resource "google_service_account" "gke_nodepool" {
  account_id = "gke-nodepool"
}
# Grant the Artifact Registry Reader role to the GKE node service account
resource "google_project_iam_member" "gke_nodepool_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodepool.email}"
}

###################################################
####################   GKE   ######################
################################################### 

resource "google_container_cluster" "gke" {
  name     = "uri-labs"
  location = "${var.region}-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private.name
  networking_mode = "VPC_NATIVE"
  deletion_protection = false
  # logging_service = "none" # Disable Google cloud managed logging
  # monitoring_service = "none" # # Disable Google cloud managed monitoring (Prometheus)
  monitoring_config {
    enable_components = []
    managed_prometheus {
      enabled = false
    }
  }
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
        disabled = true
    }
  }
  release_channel {
    channel = "REGULAR"
  }
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods"
    services_secondary_range_name = "k8s-services"
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "192.168.0.0/28"
  }
}

resource "google_container_node_pool" "nodepool" {
  name = "nodepool-1"
  cluster = google_container_cluster.gke.id
  autoscaling {
    total_min_node_count = 1
    total_max_node_count = 3
  }
  management {
    auto_upgrade = true
    auto_repair = true
  }
  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    preemptible = false
    spot = true
    disk_size_gb = 20
    disk_type = "pd-standard"
    labels = {
      role = "lab"
    }
    # taint {
    #   key    = "instance_type"
    #   value  = "spot"
    #   effect = "NO_SCHEDULE"
    # }
    service_account = google_service_account.gke_nodepool.email
  }
}

###################################################
##################    ARGOCD   ####################
###################################################

data "google_client_config" "provider" {}
provider "kubernetes" {
  host  = "https://${google_container_cluster.gke.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes = {
    host  = "https://${google_container_cluster.gke.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.gke.master_auth[0].cluster_ca_certificate
    )
  }
}
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [ google_container_cluster.gke ]
}
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "8.0.0"
  wait_for_jobs = true
  values = [
    <<EOF
global:
  domain: argocd.uri-labs.com
notifications:
  enabled: false
dex:
  enabled: false
configs:
  params:
    server.insecure: true
crds:
  install: true
controller:
  resources:
   requests:
     cpu: 25m
     memory: 64Mi
redis:
  resources:
   requests:
     cpu: 12m
     memory: 24Mi     
server:
  resources:
   requests:
     cpu: 50m
     memory: 64Mi
applicationSet:
  resources:
   requests:
     cpu: 25m
     memory: 64Mi
repoServer:
  resources:
   requests:
     cpu: 25m
     memory: 64Mi     
EOF
  ]
}

# Application Service Account
resource "google_service_account" "gke_apps" {
  account_id   = "gke-apps"
  display_name = "Service Account for applications running in GKE"
  project      = var.project_id
}

resource "google_project_iam_member" "gke_apps_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_apps.email}"
}
resource "google_project_iam_member" "gke_apps_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gke_apps.email}"
}
resource "google_project_iam_member" "gke_apps_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.gke_apps.email}"
}
resource "google_project_iam_member" "gke_apps_secrets_manager_admin" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.gke_apps.email}"
}
# IAM binding for ArgoCD Image Updater
resource "google_service_account_iam_member" "gke_apps_argocd_image_updater_wi_binding" {
  service_account_id = google_service_account.gke_apps.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-image-updater]"
  depends_on = [
    google_container_cluster.gke
  ]
}
# IAM binding for cert-manager
resource "google_service_account_iam_member" "gke_apps_cert_manager_wi_binding" {
  service_account_id = google_service_account.gke_apps.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/cert-manager]"
}

# IAM binding for Bucket-Manager App
resource "google_service_account_iam_member" "gke_apps_bucket_manager_wi_binding" {
  service_account_id = google_service_account.gke_apps.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[lab/bucket-manager]"
}
# IAM binding for External-secrets
resource "google_service_account_iam_member" "gke_apps_external_secrets_wi_binding" {
  service_account_id = google_service_account.gke_apps.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[tools/external-secrets]"
  depends_on = [
    google_container_cluster.gke
  ]
}