# AWS lab

This repository serves as a lab environment for experimenting with AWS infrastructure.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured on your local machine.

### 1. AWS CLI

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services. You'll need it to configure credentials that Terraform will use to provision resources.

#### Installation

Follow the official AWS documentation to install the AWS CLI for your operating system:
[Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

#### Configuration

Once installed, you need to configure your credentials. You can do this by running aws configure sso with the following details:
```
sso_start_url = https://d-0000000.awsapps.com/start/#
sso_region = us-east-1
sso_registration_scopes = sso:account:access
sso_session = default
region = eu-central-1
output = json
```

```sh
aws configure sso
```

then login with your sso profile
```sh
aws sso login --profile default
```

This will prompt you for your AWS Access Key ID, Secret Access Key, default AWS region, and default output format.

### 2. Terraform

Terraform is an infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure safely and efficiently.

#### Installation

Follow the official HashiCorp documentation to install Terraform:
[Install Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

## CI/CD Integration with GitHub Actions

To automate Terraform deployments, we're using GitHub Actions with OpenID Connect (OIDC).
### 1. Create an OIDC Identity Provider in AWS IAM

First, you need to set up a trust relationship between your AWS account and GitHub Actions.

1.  **Get the Thumbprint for GitHub's OIDC Provider:**
    You can get the thumbprint for `token.actions.githubusercontent.com` by running the following command. You only need the thumbprint for the top intermediate certificate authority (CA).

    ```sh
    openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -sha1 | cut -d'=' -f2 | tr -d ':'
    ```
    *Note: The thumbprint can change. Always verify it using the command above or by following the official AWS documentation.*

2.  **Create the OIDC Provider in IAM:**
    Replace `THUMBPRINT` with the value you obtained from the previous step.

    ```sh
    aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list THUMBPRINT --profile <YOUR_PROFILE>>
    ```

### 2. Create an IAM Role for GitHub Actions

Next, create an IAM role that your GitHub Actions workflow will assume.

1.  **Create the Trust Policy:**
    Create a file named `trust-policy.json` with the following content. This policy allows entities from your GitHub repository to assume the role.

    *Replace `ACCOUNT_ID`, `YOUR_GITHUB_ORG`, and `YOUR_GITHUB_REPO` with your specific details.*

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::750246861878:oidc-provider/token.actions.githubusercontent.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
            },
            "StringLike": {
              "token.actions.githubusercontent.com:sub": "repo:uri-labs/aws-prisma:*"
            }
          }
        }
      ]
    }
    ```

2.  **Create the IAM Role:**
    Use the trust policy file to create the role.

    ```sh
    aws iam create-role --role-name uri-labs-github --assume-role-policy-document trust-policy.json --profile <YOUR_PROFILE>
    ```

### 3. Attach Permissions to the IAM Role

Attach the necessary permissions to the role so that it can manage your AWS resources with Terraform.

```sh
aws iam attach-role-policy --role-name uri-labs-github --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile <YOUR_PROFILE>

```