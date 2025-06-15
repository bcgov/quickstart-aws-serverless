import { Injectable, Logger } from "@nestjs/common";
import { DynamoDBClient, DynamoDBClientConfig } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  ScanCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
} from "@aws-sdk/lib-dynamodb";

@Injectable()
export class DynamoDBService {
  private dynamoClient: DynamoDBDocumentClient;
  private tableName: string;
  constructor() {
    const clientConfig: DynamoDBClientConfig = {
      region: process.env.AWS_REGION || "ca-central-1", // Default to Canada Central if not set
      endpoint: process.env.DYNAMODB_ENDPOINT || "http://localhost:8000", // Default to local DynamoDB endpoint
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "dummy",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "dummy",
      },
    };

    const client = new DynamoDBClient(
      process.env.IS_OFFLINE ? clientConfig : {},
    );
    this.dynamoClient = DynamoDBDocumentClient.from(client);
    this.tableName = process.env.DYNAMODB_TABLE_NAME || "users";
  }

  getClient(): DynamoDBDocumentClient {
    return this.dynamoClient;
  }

  getTableName(): string {
    return this.tableName;
  }

  // Helper methods for common operations
  async get(key: any) {
    const command = new GetCommand({
      TableName: this.tableName,
      Key: key,
    });
    return this.dynamoClient.send(command);
  }

  async put(item: any) {
    const command = new PutCommand({
      TableName: this.tableName,
      Item: item,
    });
    return this.dynamoClient.send(command);
  }

  async scan(options: any = {}) {
    const command = new ScanCommand({
      TableName: this.tableName,
      ...options,
    });
    return this.dynamoClient.send(command);
  }

  async query(options: any) {
    const command = new QueryCommand({
      TableName: this.tableName,
      ...options,
    });
    return this.dynamoClient.send(command);
  }

  async update(
    key: any,
    updateExpression: string,
    expressionAttributeValues: any,
    expressionAttributeNames?: any,
  ) {
    const command = new UpdateCommand({
      TableName: this.tableName,
      Key: key,
      UpdateExpression: updateExpression,
      ExpressionAttributeValues: expressionAttributeValues,
      ...(expressionAttributeNames && {
        ExpressionAttributeNames: expressionAttributeNames,
      }),
      ReturnValues: "ALL_NEW",
    });
    return this.dynamoClient.send(command);
  }

  async delete(key: any) {
    const command = new DeleteCommand({
      TableName: this.tableName,
      Key: key,
    });
    return this.dynamoClient.send(command);
  }
}
