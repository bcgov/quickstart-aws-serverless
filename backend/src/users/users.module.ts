import { Module } from "@nestjs/common";
import { UsersService } from "./users.service";
import { UsersController } from "./users.controller";
import { DynamoDBModule } from "src/dynamodb.module";

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  imports: [DynamoDBModule]
})
export class UsersModule {
}
