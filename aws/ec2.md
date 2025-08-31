# EC2 Manager Script

A Python script to manage EC2 instances using boto3, filtering by Name tags.

## Prerequisites

- Python 3.x
- boto3: `pip install boto3`
- AWS CLI configured with SSO (as per project README)

## Usage

```bash
python3 ec2_manager.py <action> [name_filter]
```

### Actions

#### List all instances
```bash
python3 ec2_manager.py list
```
Output: `ID: i-xxx, Name: instance-name, State: running, IP: 1.2.3.4`

#### Start instances
```bash
python3 ec2_manager.py start "ec2-lab-instance-*"
python3 ec2_manager.py start "ec2-lab-instance-one"
```

#### Stop instances
```bash
python3 ec2_manager.py stop "ec2-lab-instance-*"
python3 ec2_manager.py stop "ec2-lab-instance-two"
```

#### Terminate instances
```bash
python3 ec2_manager.py terminate "ec2-lab-instance-three"
```

## Name Filter Patterns

- `"ec2-lab-instance-*"` - matches all lab instances
- `"ec2-lab-instance-one"` - matches specific instance
- `"*"` - matches all instances

## Notes

- Uses your AWS CLI region configuration (eu-central-1)
- Shows instance ID and public IP before each action
- Excludes terminated instances from operations
- Displays "N/A" for instances without public IPs