PostgreSQL VM
resource "google_compute_instance" "postgres" {
  project      = var.project_id
  zone         = "${var.region}-a"
  name         = "postgresql"
  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 14
    }
  }

  network_interface {
    network    = "main"
    subnetwork = google_compute_subnetwork.public.id
    access_config {}
  }

  tags = ["allow-postgres", "allow-ssh"]

#   service_account {
#     email  = ""
#     scopes = ["cloud-platform"]
#   }

  metadata = {
    block-project-ssh-keys = true
    startup-script   = <<-EOF
#!/bin/bash
LOGFILE="startup_logs.log"
echo "Starting PostgreSQL deployment at $(date)" | tee -a $LOGFILE

# Update apt and install tools
apt-get update -y | tee -a $LOGFILE
apt-get install -y ca-certificates curl wget | tee -a $LOGFILE

# Install Docker
install -m 0755 -d /etc/apt/keyrings | tee -a $LOGFILE
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc | tee -a $LOGFILE
chmod a+r /etc/apt/keyrings/docker.asc | tee -a $LOGFILE

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list | tee -a $LOGFILE

apt-get update | tee -a $LOGFILE
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | tee -a $LOGFILE
groupadd docker | tee -a $LOGFILE
usermod -aG docker $USER | tee -a $LOGFILE

# Create docker-compose.yml for PostgreSQL
cat > /home/docker-compose.yml << 'EOT'
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: eq
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: eqpostgresql
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
EOT

# Start PostgreSQL
cd /home
docker compose up -d | tee -a $LOGFILE
echo "PostgreSQL started at $(date)" | tee -a $LOGFILE

EOF
  }
}