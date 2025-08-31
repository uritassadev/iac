# GCE Manager Script

A Python script to manage Google Compute Engine (GCE) instances using the `google-cloud-compute` library, similar to the AWS EC2 manager.

## Prerequisites

- Python 3.x
- Google Cloud SDK for Python: `pip install google-cloud-compute`
- `gcloud` CLI tool installed and authenticated.

## Configuration

The script requires a Google Cloud Project ID to work. It will attempt to find it in the following order:
1.  The `GCP_PROJECT` environment variable.
2.  The output of `gcloud config get-value project`.

It also relies on Application Default Credentials (ADC). To set this up, run:
```bash
# Log in to your Google account
gcloud auth login

# Set up application-default credentials
gcloud auth application-default login

# Configure your default project
gcloud config set project YOUR_PROJECT_ID
```

## Usage

```bash
python3 gce_manager.py <action> [name_filter]
```

### Actions

#### List all instances
```bash
python3 gce_manager.py list
```
Output: `Name: instance-1    ID: 123...    Zone: us-central1-a    Status: RUNNING    IP: 1.2.3.4`

#### Start instances
Start a specific instance:
```bash
python3 gce_manager.py start "gce-lab-instance-one"
```
Start multiple instances using a wildcard:
```bash
python3 gce_manager.py start "gce-lab-instance-*"
```

#### Stop instances
```bash
python3 gce_manager.py stop "gce-lab-instance-*"
python3 gce_manager.py stop "gce-lab-instance-two"
```

#### Delete instances (Terminate)
**Warning: This is a destructive and irreversible action.**
```bash
python3 gce_manager.py delete "gce-lab-instance-three"
```
The script will ask for confirmation before proceeding with deletion.

## Name Filter Patterns

The `name_filter` argument supports wildcards.
-   `"gce-lab-instance-*"` - matches all instances with that prefix.
-   `"gce-lab-instance-one"` - matches a specific instance.
-   `"*"` - matches all instances (required for `start`, `stop`, `delete` if you want to target all VMs).

## Notes

- The script lists instances across all zones within the configured project.
- It shows instance name, ID, zone, status, and external IP.
- It excludes `TERMINATED` instances from all operations.
- For destructive actions, it prints the targeted instances and asks for confirmation.
- It displays "N/A" for instances without an external IP address.