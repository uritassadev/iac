module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.103.0/24", "10.0.104.0/24"]

  enable_nat_gateway = true
  single_nat_gateway  = true
  enable_dns_hostnames = true
  enable_dns_support = true
  manage_default_security_group = false

  tags = {
    Terraform = "true"
    Project = "Lab"
  }
}