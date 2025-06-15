import { Module } from "@nestjs/common";
import { DynamoDBService } from "src/dynamodb.service";

@Module({
  providers: [DynamoDBService],
  exports: [DynamoDBService],
})
export class DynamoDBModule {}
