resource "google_storage_bucket" "general_purpose" {
  name          = "urigsbucket5202"
  force_destroy = true
  location      = "us-central1"
  storage_class = "STANDARD"
  public_access_prevention = "enforced"

  uniform_bucket_level_access = true
}