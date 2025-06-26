#!/bin/bash
# This script resumes AWS resources (ECS service) in the specified AWS account.
# Note: DynamoDB doesn't require resuming like RDS as it's always available

set -e  # Exit on error

# Error handling function
error_handler() {
    local line=$1
    local func=$2
    echo "Error occurred at line ${line} in function ${func}"
    exit 1
}

# Set trap for error handling
trap 'error_handler ${LINENO} ${FUNCNAME[0]}' ERR

# Function to check if required parameters are provided
check_parameters() {
    local env=$1
    local prefix=$2
    
    if [ -z "$env" ] || [ -z "$prefix" ]; then
        echo "Usage: $0 <environment> <stack-prefix>"
        echo "Example: $0 dev myapp"
        exit 1
    fi
}
# Check if ECS cluster exists
function check_ecs_cluster() {
    local status=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" \
                  --query 'clusters[0].status' --output text 2>/dev/null || echo "INACTIVE")
    echo "$status"
}


# Function to resume ECS service
resume_ecs_service() {
    local prefix=$1
    local env=$2
    local cluster_status=$3
    
    if [ "$cluster_status" != "ACTIVE" ]; then
        echo "Skipping ECS resume operation: Cluster $CLUSTER_NAME does not exist"
        return
    fi
    #check if service exists
    local service_status=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" \
                          --query 'services[0].status' --output text 2>/dev/null || echo "INACTIVE")
    if [ "$service_status" != "ACTIVE" ]; then
        echo "Skipping ECS resume operation: Service $SERVICE_NAME does not exist in cluster $CLUSTER_NAME"
        return
    fi
    echo "Resuming ECS service ${SERVICE_NAME} on cluster ${CLUSTER_NAME}..."
    # Update scaling policy
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id service/${CLUSTER_NAME}/${SERVICE_NAME} \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity 1 \
        --max-capacity 2 \
        --no-cli-pager \
        --output json
    
    # Update service desired count
    aws ecs update-service \
        --cluster ${CLUSTER_NAME} \
        --service ${SERVICE_NAME} \
        --desired-count 1 \
        --no-cli-pager \
        --output json
        
    echo "ECS service has been resumed"
}

# Main function
main() {
    local env=$1
    local prefix=$2
    
    echo "Starting to resume resources for environment: ${env} with stack prefix: ${prefix}"
    # Check and pause ECS service
    ecs_status=$(check_ecs_cluster)
    [ "$ecs_status" = "INACTIVE" ] || echo "ECS cluster status: $ecs_status"
    # Resume ECS service (DynamoDB is always available)
    resume_ecs_service "$prefix" "$env" "$ecs_status"
    
    echo "Resources have been resumed successfully"
}

# Parse and check arguments
ENVIRONMENT=${1}
STACK_PREFIX=${2}
CLUSTER_NAME="${STACK_PREFIX}-node-api-${ENVIRONMENT}"
SERVICE_NAME="${STACK_PREFIX}-node-api-${ENVIRONMENT}"
check_parameters "$ENVIRONMENT" "$STACK_PREFIX"

# Execute main function
main "$ENVIRONMENT" "$STACK_PREFIX"