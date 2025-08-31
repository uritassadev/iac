resource "google_artifact_registry_repository" "artifactory" {
  location = local.region
  project  = local.project_id
  repository_id = "uri-labs"
  description   = "artifact registry"
  format        = "DOCKER"
  vulnerability_scanning_config {
    enablement_config = "DISABLED"
  }
}