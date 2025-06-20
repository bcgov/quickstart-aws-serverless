import { Injectable } from "@nestjs/common";
import { DynamoDBService } from "src/dynamodb.service";
import { v4 as uuidv4 } from "uuid";

import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { UserDto } from "./dto/user.dto";

@Injectable()
export class UsersService {
  constructor(
    private dynamoDBService: DynamoDBService
  ) {
  }

  async create(user: CreateUserDto): Promise<UserDto> {
    const id = uuidv4();
    const newUser = {
      id,
      name: user.name,
      email: user.email,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await this.dynamoDBService.put(newUser);

    return {
      id,
      name: user.name,
      email: user.email
    };
  }

  async findAll(): Promise<UserDto[]> {
    const result = await this.dynamoDBService.scan();
    const users = result.Items || [];
    return users.map(user => ({
      id: user.id,
      name: user.name,
      email: user.email
    })).sort((a, b) => a.id.localeCompare(b.id));
  }

  async findOne(id: string): Promise<UserDto> {
    const result = await this.dynamoDBService.get({ id });
    const user = result.Item;
    
    if (!user) {
      throw new Error(`User with id ${id} not found`);
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email
    };
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<UserDto> {
    const updateExpression = "SET #name = :name, #email = :email, updatedAt = :updatedAt";
    const expressionAttributeNames = {
      "#name": "name",
      "#email": "email"
    };
    const expressionAttributeValues = {
      ":name": updateUserDto.name,
      ":email": updateUserDto.email,
      ":updatedAt": new Date().toISOString()
    };

    const result = await this.dynamoDBService.update(
      { id },
      updateExpression,
      expressionAttributeValues,
      expressionAttributeNames
    );

    return {
      id: result.Attributes.id,
      name: result.Attributes.name,
      email: result.Attributes.email
    };
  }

  async remove(id: string): Promise<{ deleted: boolean; message?: string }> {
    try {
      await this.dynamoDBService.delete({ id });
      return { deleted: true };
    } catch (err) {
      return { deleted: false, message: err.message };
    }
  }

  async searchUsers(page: number,
                    limit: number,
                    sort: string, // JSON string for sort configuration
                    filter: string // JSON string for filter configuration
  ): Promise<any> {

    page = page || 1;
    if (!limit || limit > 200) {
      limit = 10;
    }

    // For simplicity, implementing basic scan with pagination
    // In production, you might want to use DynamoDB's pagination features
    const result = await this.dynamoDBService.scan({
      Limit: limit,
      // Note: DynamoDB pagination is different from SQL OFFSET
      // You would typically use LastEvaluatedKey for pagination
    });

    const users = (result.Items || []).map(user => ({
      id: user.id,
      name: user.name,
      email: user.email
    }));    return {
      users,
      totalCount: result.Count || 0,
      page,
      limit
    };
  }
}
