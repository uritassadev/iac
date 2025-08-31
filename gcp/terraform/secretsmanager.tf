# Generates a random password.
resource "random_password" "pg_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Creates a secret in Secret Manager to store the database password.
resource "google_secret_manager_secret" "pg_db_password_secret" {
  project   = var.project_id
  secret_id = "pg-db-password"

  replication {
    auto {}
  }
}

# Adds a version to the secret with the generated database password.
resource "google_secret_manager_secret_version" "pg_db_password_secret_version" {
  secret      = google_secret_manager_secret.pg_db_password_secret.id
  secret_data = random_password.pg_db_password.result
}