module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  # Secret
  name_prefix             = "lab-secrets"
  description             = "Lab Secrets Manager secret"
  recovery_window_in_days = 7
  secret_string           = "{}"
  ignore_secret_changes   = true


  tags = {
    Environment = "Lab"
    Project     = "Lab"
    Terraform = true
  }
}