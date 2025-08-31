#!/usr/bin/env python3
"""
A manager script for Google Compute Engine (GCE) virtual machines.
"""
import sys
import os
import subprocess
from google.cloud import compute_v1
from google.api_core.exceptions import GoogleAPICallError

def get_gcp_project_id():
    """Retrieves the GCP Project ID from env var or gcloud config."""
    project_id = os.environ.get('GCP_PROJECT')
    if project_id:
        return project_id
    try:
        project_id = subprocess.check_output(
            ['gcloud', 'config', 'get-value', 'project'],
            stderr=subprocess.PIPE
        ).strip().decode('utf-8')
        if project_id:
            return project_id
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: GCP project ID not found.", file=sys.stderr)
        print("Please set the GCP_PROJECT environment variable or configure it using 'gcloud config set project YOUR_PROJECT_ID'.", file=sys.stderr)
        sys.exit(1)
    return None

def get_instances(project_id, name_filter=None):
    """
    Retrieves a list of GCE instances, optionally filtered by name.
    """
    instances_client = compute_v1.InstancesClient()
    request = compute_v1.AggregatedListInstancesRequest(project=project_id)

    if name_filter and name_filter != '*':
        request.filter = f"name = {name_filter}"

    all_instances = []
    try:
        # The Pager object is an iterator of (zone, response) tuples.
        for zone, response in instances_client.aggregated_list(request=request):
            if response.instances:
                for instance in response.instances:
                    # GCE keeps deleted instances in TERMINATED state for a while.
                    if instance.status != 'TERMINATED':
                        external_ip = 'N/A'
                        if instance.network_interfaces:
                            for iface in instance.network_interfaces:
                                if iface.access_configs:
                                    for access_config in iface.access_configs:
                                        if access_config.nat_i_p:
                                            external_ip = access_config.nat_i_p
                                            break
                                if external_ip != 'N/A':
                                    break

                        all_instances.append({
                            'name': instance.name,
                            'id': instance.id,
                            'zone': zone.split('/')[-1],
                            'status': instance.status,
                            'ip': external_ip
                        })
    except GoogleAPICallError as e:
        print(f"An API error occurred: {e}", file=sys.stderr)
        sys.exit(1)

    return all_instances

def list_all_instances(project_id):
    """Lists all non-terminated GCE instances."""
    instances = get_instances(project_id, name_filter='*')
    if not instances:
        print("No running or stopped instances found.")
        return

    for inst in sorted(instances, key=lambda i: i['name']):
        print(
            f"Name: {inst['name']:<30} "
            f"ID: {inst['id']:<22} "
            f"Zone: {inst['zone']:<20} "
            f"Status: {inst['status']:<12} "
            f"IP: {inst['ip']}"
        )

def start_instances(project_id, name_filter):
    """Starts instances matching the name filter."""
    instances = get_instances(project_id, name_filter)
    if not instances:
        print("No instances found to start.")
        return

    print("The following instances will be started:")
    client = compute_v1.InstancesClient()
    for inst in instances:
        print(f"  Name: {inst['name']}, Zone: {inst['zone']}")
        if inst['status'] == 'RUNNING':
            print(f"  -> Instance '{inst['name']}' is already running.")
            continue
        try:
            print(f"  -> Sending start command to '{inst['name']}' in zone '{inst['zone']}'...")
            client.start(project=project_id, zone=inst['zone'], instance=inst['name'])
        except GoogleAPICallError as e:
            print(f"  -> Error starting instance {inst['name']}: {e}", file=sys.stderr)
    print("\nStart command sent to all targeted instances.")

def stop_instances(project_id, name_filter):
    """Stops instances matching the name filter."""
    instances = get_instances(project_id, name_filter)
    if not instances:
        print("No instances found to stop.")
        return

    print("The following instances will be stopped:")
    client = compute_v1.InstancesClient()
    for inst in instances:
        print(f"  Name: {inst['name']}, Zone: {inst['zone']}")
        if inst['status'] != 'RUNNING':
            print(f"  -> Instance '{inst['name']}' is not running.")
            continue
        try:
            print(f"  -> Sending stop command to '{inst['name']}' in zone '{inst['zone']}'...")
            client.stop(project=project_id, zone=inst['zone'], instance=inst['name'])
        except GoogleAPICallError as e:
            print(f"  -> Error stopping instance {inst['name']}: {e}", file=sys.stderr)
    print("\nStop command sent to all targeted instances.")


def delete_instances(project_id, name_filter):
    """Deletes (terminates) instances matching the name filter."""
    instances = get_instances(project_id, name_filter)
    if not instances:
        print("No instances found to delete.")
        return

    print("The following instances will be PERMANENTLY DELETED:")
    for inst in instances:
        print(f"  Name: {inst['name']}, Zone: {inst['zone']}, Status: {inst['status']}")

    confirm = input("\nAre you sure you want to delete these instances? This action cannot be undone. [y/N]: ")
    if confirm.lower() != 'y':
        print("Deletion cancelled.")
        return

    client = compute_v1.InstancesClient()
    for inst in instances:
        try:
            print(f"Deleting instance '{inst['name']}' in zone '{inst['zone']}'...")
            client.delete(project=project_id, zone=inst['zone'], instance=inst['name'])
        except GoogleAPICallError as e:
            print(f"  Error deleting instance {inst['name']}: {e}", file=sys.stderr)
    print("\nDelete command sent to all targeted instances.")

def main():
    """Main function to parse arguments and call the appropriate action."""
    if len(sys.argv) < 2:
        print("Usage: python3 gce_manager.py <action> [name_filter]")
        print("Actions: list, start, stop, delete")
        print("\nName Filter Patterns:")
        print("  \"instance-name\"      - matches a specific instance")
        print("  \"instance-prefix-*\"  - matches all instances with a prefix")
        print("  \"*\"                  - matches all instances (for actions other than list)")
        sys.exit(1)

    action = sys.argv[1].lower()
    project_id = get_gcp_project_id()

    if action == "list":
        list_all_instances(project_id)
    elif action in ["start", "stop", "delete"]:
        if len(sys.argv) < 3:
            print(f"Error: The '{action}' action requires a name_filter.", file=sys.stderr)
            sys.exit(1)
        name_filter = sys.argv[2]
        if action == "start":
            start_instances(project_id, name_filter)
        elif action == "stop":
            stop_instances(project_id, name_filter)
        elif action == "delete":
            delete_instances(project_id, name_filter)
    else:
        print(f"Error: Invalid action '{action}'.", file=sys.stderr)
        print("Valid actions are: list, start, stop, delete.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()