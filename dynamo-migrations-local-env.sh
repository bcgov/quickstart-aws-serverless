#!/bin/bash
# This script initializes a DynamoDB table for local development.
# It creates a table named 'users' with a primary key 'id' and a GSI on 'email'.
if ! aws dynamodb describe-table --endpoint-url http://dynamodb-local:8000 --table-name users 2>/dev/null; then
  echo 'Creating users table...'
  aws dynamodb create-table \
    --endpoint-url http://dynamodb-local:8000 \
    --table-name users \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=email,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --global-secondary-indexes \
      '[{"IndexName":"EmailIndex","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST
  
  echo 'Waiting for table to be active...'
  aws dynamodb wait table-exists --endpoint-url http://dynamodb-local:8000 --table-name users
else
  echo 'Table users already exists'
fi

# Add sample users
echo 'Adding sample users...'

# User 1
aws dynamodb put-item \
  --endpoint-url http://dynamodb-local:8000 \
  --table-name users \
  --item '{"id":{"S":"1"},"name":{"S":"John"},"email":{"S":"John.ipsum@test.com"}}' \
  --condition-expression "attribute_not_exists(id)" 2>/dev/null || echo "User 1 already exists"

# User 2
aws dynamodb put-item \
  --endpoint-url http://dynamodb-local:8000 \
  --table-name users \
  --item '{"id":{"S":"2"},"name":{"S":"Jane"},"email":{"S":"Jane.ipsum@test.com"}}' \
  --condition-expression "attribute_not_exists(id)" 2>/dev/null || echo "User 2 already exists"

# User 3
aws dynamodb put-item \
  --endpoint-url http://dynamodb-local:8000 \
  --table-name users \
  --item '{"id":{"S":"3"},"name":{"S":"Jack"},"email":{"S":"Jack.ipsum@test.com"}}' \
  --condition-expression "attribute_not_exists(id)" 2>/dev/null || echo "User 3 already exists"
# User 4
aws dynamodb put-item \
  --endpoint-url http://dynamodb-local:8000 \
  --table-name users \
  --item '{"id":{"S":"4"},"name":{"S":"Jill"},"email":{"S":"Jill.ipsum@test.com"}}' \
  --condition-expression "attribute_not_exists(id)" 2>/dev/null || echo "User 4 already exists"
# User 5
aws dynamodb put-item \
  --endpoint-url http://dynamodb-local:8000 \
  --table-name users \
  --item '{"id":{"S":"5"},"name":{"S":"Joe"},"email":{"S":"Joe.ipsum@test.com"}}' \
  --condition-expression "attribute_not_exists(id)" 2>/dev/null || echo "User 5 already exists"

echo 'Listing tables...'
aws dynamodb list-tables --endpoint-url http://dynamodb-local:8000

echo 'DynamoDB initialization completed successfully'