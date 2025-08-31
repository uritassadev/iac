locals {
    apis = [
        "compute.googleapis.com",
        "container.googleapis.com",
        "logging.googleapis.com",
        "secretmanager.googleapis.com",
        "containerscanning.googleapis.com",
        "vpcaccess.googleapis.com",
        "artifactregistry.googleapis.com",
        "iam.googleapis.com",
        "run.googleapis.com"
    ]
    zone   = "us-central1-a"
}
# Enable APIs
resource "google_project_service" "api" {
    for_each = toset(local.apis)
    service = each.key
    disable_on_destroy = false
}