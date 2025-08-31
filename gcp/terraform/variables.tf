variable "project_id" {
    description = "Google cloud project ID"
    type = string
}
variable "project_number {
    description = "Google cloud project number"
    type = string
}
variable "region {
    default = "us-central1"
    description = "Google cloud region"
    type = string
}
variable "service_account {
    description = "Google cloud IAM service account"
    type = string
}
