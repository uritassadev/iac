######################################################### cloud run #######################################################

#resource "google_cloud_run_service" "uriweb" {
#   project  = var.project_id
#   location = var.region
#   name     = "uriweb"

#   template {
#     spec {
#       containers {
#         image = "<FULL_IMAGE>"
#         ports {
#           container_port = 8080 # Next.js app listens on 8080 as per Dockerfile
#         }
#       }
#     }
#   }

#   traffic {
#     percent = 100
#     latest_revision = true
#   }

#   autogenerate_revision_name = true

#   depends_on = [
#     google_artifact_registry_repository.artifactory
#   ]
# }
# resource "google_cloud_run_service_iam_member" "public_access" {
#   project  = google_cloud_run_service.uriweb.project
#   location = google_cloud_run_service.uriweb.location
#   service  = google_cloud_run_service.uriweb.name
#   role     = "roles/run.invoker"
#   member   = "allUsers" # This line grants access to everyone
# }