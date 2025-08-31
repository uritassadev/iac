# VPC
resource "google_compute_network" "vpc" {
    name = "main"
    routing_mode = "REGIONAL"
    auto_create_subnetworks = false
    delete_default_routes_on_create = true
    depends_on = [google_project_service.api]
}

# Creates a default route that sends all outbound traffic (0.0.0.0/0) to the default internet gateway of the VPC network.
resource "google_compute_route" "default_route" {
    name = "default-route"
    dest_range = "0.0.0.0/0"
    network = google_compute_network.vpc.name
    next_hop_gateway = "default-internet-gateway"
}


# Creates a public subnetwork
resource "google_compute_subnetwork" "public" {
  name          = "public"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type = "IPV4_ONLY"
}

# Creates a private subnetwork 
resource "google_compute_subnetwork" "private" {
  name          = "private"
  ip_cidr_range = "10.0.16.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type = "IPV4_ONLY"
  secondary_ip_range {
    range_name    = "k8s-pods"
    ip_cidr_range = "172.16.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-services"
    ip_cidr_range = "172.20.0.0/20"
  }
}

# Reserves a static external IP address named "nat-static-ip" in the specified region
resource "google_compute_address" "nat_ip" {
  name         = "nat-static-ip"
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
  region       = var.region
  depends_on   = [google_project_service.api]
}

# Creates a Cloud Router named "nat-router" in the specified region.
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Configures a Cloud NAT gateway named "nat-gateway" on the "nat-router"
# in the specified region. It uses a manually allocated static IP address
# and will NAT traffic from all IP ranges in the specified subnetworks.
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  subnetwork {
    name = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}