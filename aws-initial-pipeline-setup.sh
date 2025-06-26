#!/bin/bash

# Script to create AWS IAM policy and role for GitHub Actions deployment
# This automates the steps described in AWS-DEPLOY.md

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate input
validate_input() {
    local input="$1"
    local field="$2"
    
    if [[ -z "$input" ]]; then
        print_error "$field cannot be empty"
        exit 1
    fi
}

# Function to validate AWS account number
validate_account_number() {
    local account="$1"
    if [[ ! "$account" =~ ^[0-9]{12}$ ]]; then
        print_error "AWS account number must be exactly 12 digits"
        exit 1
    fi
}

# Function to validate GitHub repo format
validate_repo_format() {
    local repo="$1"
    if [[ ! "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
        print_error "Repository name must be in format 'owner/repo-name'"
        exit 1
    fi
}

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or you don't have permissions. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is properly configured"
}

# Function to create IAM policy
create_iam_policy() {
    local policy_name="$1"
    
    print_status "Creating IAM policy: $policy_name"
    
    # Create policy document
    cat > /tmp/terraform-deploy-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAM",
      "Effect": "Allow",
      "Action": ["iam:*"],
      "Resource": ["*"]
    },
    {
      "Sid": "S3",
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": ["*"]
    },
    {
      "Sid": "Cloudfront",
      "Effect": "Allow",
      "Action": ["cloudfront:*"],
      "Resource": ["*"]
    },
    {
      "Sid": "ecs",
      "Effect": "Allow",
      "Action": ["ecs:*"],
      "Resource": "*"
    },
    {
      "Sid": "ecr",
      "Effect": "Allow",
      "Action": ["ecr:*"],
      "Resource": "*"
    },
    {
      "Sid": "Dynamodb",
      "Effect": "Allow",
      "Action": ["dynamodb:*"],
      "Resource": ["*"]
    },
    {
      "Sid": "APIgateway",
      "Effect": "Allow",
      "Action": ["apigateway:*"],
      "Resource": ["*"]
    },
    {
      "Sid": "RDS",
      "Effect": "Allow",
      "Action": ["rds:*"],
      "Resource": "*"
    },
    {
      "Sid": "Cloudwatch",
      "Effect": "Allow",
      "Action": ["cloudwatch:*"],
      "Resource": "*"
    },
    {
      "Sid": "EC2",
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": "*"
    },
    {
      "Sid": "Autoscaling",
      "Effect": "Allow",
      "Action": ["autoscaling:*"],
      "Resource": "*"
    },
    {
      "Sid": "KMS",
      "Effect": "Allow",
      "Action": ["kms:*"],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManager",
      "Effect": "Allow",
      "Action": ["secretsmanager:*"],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": ["logs:*"],
      "Resource": "*"
    },
    {
      "Sid": "WAF",
      "Effect": "Allow",
      "Action": ["wafv2:*"],
      "Resource": "*"
    },
    {
      "Sid": "ELB",
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": "*"
    },
    {
      "Sid": "AppAutoScaling",
      "Effect": "Allow",
      "Action": ["application-autoscaling:*"],
      "Resource": "*"
    }
  ]
}
EOF

    # Check if policy already exists
    if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_NUMBER}:policy/${policy_name}" &> /dev/null; then
        print_warning "Policy $policy_name already exists. Updating policy..."
        
        # Get current policy version
        current_version=$(aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_NUMBER}:policy/${policy_name}" --query 'Policy.DefaultVersionId' --output text)
        
        # Create new policy version
        aws iam create-policy-version \
            --policy-arn "arn:aws:iam::${AWS_ACCOUNT_NUMBER}:policy/${policy_name}" \
            --policy-document file:///tmp/terraform-deploy-policy.json \
            --set-as-default > /dev/null
        
        print_success "Policy $policy_name updated successfully"
    else
        # Create new policy
        POLICY_ARN=$(aws iam create-policy \
            --policy-name "$policy_name" \
            --policy-document file:///tmp/terraform-deploy-policy.json \
            --description "Policy for GitHub Actions to deploy infrastructure via Terraform" \
            --query 'Policy.Arn' \
            --output text)
        
        print_success "Policy created: $POLICY_ARN"
    fi
    
    # Clean up temporary file
    rm -f /tmp/terraform-deploy-policy.json
}

# Function to create IAM role
create_iam_role() {
    local role_name="$1"
    local repo_name="$2"
    local account_number="$3"
    local policy_name="$4"
    
    print_status "Creating IAM role: $role_name"
    
    # Create trust policy document
    cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_number}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${repo_name}:*"
                },
                "ForAllValues:StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:iss": "https://token.actions.githubusercontent.com"
                }
            }
        }
    ]
}
EOF

    local role_arn
    # Check if role already exists
    if aws iam get-role --role-name "$role_name" &> /dev/null; then
        print_warning "Role $role_name already exists. Updating trust policy..."
        
        # Update trust policy
        aws iam update-assume-role-policy \
            --role-name "$role_name" \
            --policy-document file:///tmp/trust-policy.json
        
        print_success "Role trust policy updated"
        role_arn="arn:aws:iam::${account_number}:role/${role_name}"
    else
        # Create new role
        role_arn=$(aws iam create-role \
            --role-name "$role_name" \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --description "Role for GitHub Actions to deploy infrastructure via Terraform" \
            --query 'Role.Arn' \
            --output text)
        
        print_success "Role created: $role_arn"
        
        # Wait for role to propagate through AWS systems
        print_status "Waiting for IAM role to propagate..."
        max_attempts=10
        attempt=1
        while [ $attempt -le $max_attempts ]; do
            if aws iam get-role --role-name "$role_name" &> /dev/null; then
                print_success "Role $role_name is now available"
                break
            else
                print_status "Attempt $attempt of $max_attempts: Role not yet available, waiting..."
                sleep 3
                ((attempt++))
            fi
        done
        
        if [ $attempt -gt $max_attempts ]; then
            print_warning "Role may not be fully propagated yet, but proceeding anyway"
        fi
    fi
    
    # Attach policy to role
    print_status "Attaching policy to role..."
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::${account_number}:policy/${policy_name}"
    
    print_success "Policy attached to role"
    
    # Clean up temporary file
    rm -f /tmp/trust-policy.json
    
    # Write role ARN to a temporary file instead of echoing it
    echo "$role_arn" > /tmp/role_arn.txt
}


# Main script
main() {
    print_status "AWS IAM Policy and Role Setup for GitHub Actions"
    print_status "=============================================="
    echo
    
    # Check AWS CLI
    check_aws_cli
    echo
    
    # Get current AWS account number
    CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    print_status "Current AWS Account: $CURRENT_ACCOUNT"
    echo
    
    # Collect user input
    read -p "Enter GitHub repository name (format: owner/repo-name): " REPO_NAME
    validate_input "$REPO_NAME" "Repository name"
    validate_repo_format "$REPO_NAME"
    
    read -p "Enter AWS account number [$CURRENT_ACCOUNT]: " AWS_ACCOUNT_NUMBER
    AWS_ACCOUNT_NUMBER=${AWS_ACCOUNT_NUMBER:-$CURRENT_ACCOUNT}
    validate_account_number "$AWS_ACCOUNT_NUMBER"
    
    read -p "Enter IAM policy name [TerraformDeployPolicy]: " POLICY_NAME
    POLICY_NAME=${POLICY_NAME:-TerraformDeployPolicy}
    validate_input "$POLICY_NAME" "Policy name"
    
    read -p "Enter IAM role name [GHA_CI_CD]: " ROLE_NAME
    ROLE_NAME=${ROLE_NAME:-GHA_CI_CD}
    validate_input "$ROLE_NAME" "Role name"
    
    echo
    print_status "Configuration Summary:"
    echo "  Repository: $REPO_NAME"
    echo "  AWS Account: $AWS_ACCOUNT_NUMBER"
    echo "  Policy Name: $POLICY_NAME"
    echo "  Role Name: $ROLE_NAME"
    echo
    
    read -p "Do you want to proceed? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        exit 0
    fi
    
    echo
    print_status "Starting deployment setup..."
    
    
    # Create IAM policy
    create_iam_policy "$POLICY_NAME"
    echo
    
    # Create IAM role
    create_iam_role "$ROLE_NAME" "$REPO_NAME" "$AWS_ACCOUNT_NUMBER" "$POLICY_NAME"
    
    # Read the role ARN from the temporary file
    ROLE_ARN=$(cat /tmp/role_arn.txt)
    rm -f /tmp/role_arn.txt
    echo
    
    print_success "Setup completed successfully!"
    echo
    print_status "Next Steps:"
    echo "1. Add the following secrets to your GitHub repository:"
    echo "   - AWS_DEPLOY_ROLE_ARN: $ROLE_ARN"
    echo "   - AWS_LICENSE_PLATE: <your-6-character-license-plate>"
    echo
    echo "2. You can add these secrets via:"
    echo "   - Repository Settings > Secrets and variables > Actions"
    echo "   - Or use GitHub CLI: gh secret set AWS_DEPLOY_ROLE_ARN --body \"$ROLE_ARN\""
    echo
    print_status "Your GitHub Actions workflows should now be able to deploy to AWS!"
}

# Run main function
main "$@"