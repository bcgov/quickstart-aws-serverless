#!/bin/bash
# This script pauses AWS resources (ECS service) in the current AWS account.
# Note: DynamoDB doesn't require pausing like RDS as it's pay-per-request

set -e  # Exit on error

# Error handler function
function error_handler() {
    local script_name=$(basename "$0")
    echo "Error in script: $script_name"
    echo "Error occurred at line $LINENO in function ${FUNCNAME[1]}"
    exit 1
}

trap 'error_handler' ERR
# Parse arguments
ENVIRONMENT=${1}
STACK_PREFIX=${2}
CLUSTER_NAME="${STACK_PREFIX}-node-api-${ENVIRONMENT}"
SERVICE_NAME="${STACK_PREFIX}-node-api-${ENVIRONMENT}"
# Validate required arguments
function validate_args() {
    if [ -z "$ENVIRONMENT" ]; then
        echo "Error: Environment is required as the first parameter"
        exit 1
    fi
    if [ -z "$STACK_PREFIX" ]; then
        echo "Error: Stack prefix is required as the second parameter"
        exit 1
    fi
}



# Check if ECS cluster exists
function check_ecs_cluster() {
    local status=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" \
                  --query 'clusters[0].status' --output text 2>/dev/null || echo "INACTIVE")
    echo "$status"
}

# Pause ECS service by setting min/max capacity to 0
function pause_ecs_service() {
    local cluster_status=$1
    
    if [ "$cluster_status" != "ACTIVE" ]; then
        echo "Skipping ECS pause operation: Cluster $CLUSTER_NAME does not exist"
        return
    fi
    
    local service_status=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" \
                          --query 'services[0].status' --output text 2>/dev/null || echo "INACTIVE")
    
    if [ "$service_status" = "ACTIVE" ]; then
        echo "Scaling down ECS service: $SERVICE_NAME"
        aws application-autoscaling register-scalable-target \
            --service-namespace ecs \
            --resource-id "service/$CLUSTER_NAME/$SERVICE_NAME" \
            --scalable-dimension ecs:service:DesiredCount \
            --min-capacity 0 \
            --max-capacity 0 \
            --no-cli-pager \
            --output json
    else
        echo "ECS service $SERVICE_NAME does not exist in cluster $CLUSTER_NAME"
    fi
}

# Main execution
validate_args

# Check and pause ECS service
ecs_status=$(check_ecs_cluster)
[ "$ecs_status" = "INACTIVE" ] || echo "ECS cluster status: $ecs_status"

# Perform pause operations
pause_ecs_service "$ecs_status"

echo "Pause completed. Note: DynamoDB doesn't require pausing as it uses pay-per-request billing."

echo "Pause operations completed"