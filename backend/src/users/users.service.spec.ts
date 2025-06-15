import type { TestingModule } from "@nestjs/testing";
import { Test } from "@nestjs/testing";
import { UsersService } from "./users.service";
import { DynamoDBService } from "src/dynamodb.service";

// Mock UUID to return predictable values for testing
vi.mock("uuid", () => ({
  v4: vi.fn(() => "test-uuid-123"),
}));

describe("UserService", () => {
  let service: UsersService;
  let dynamoDBService: DynamoDBService;

  const mockUser1 = {
    id: "test-uuid-123",
    name: "Test Numone",
    email: "numone@test.com",
    createdAt: "2024-01-01T00:00:00.000Z",
    updatedAt: "2024-01-01T00:00:00.000Z",
  };

  const mockUser2 = {
    id: "test-uuid-456",
    name: "Test Numtwo",
    email: "numtwo@test.com",
    createdAt: "2024-01-01T00:00:00.000Z",
    updatedAt: "2024-01-01T00:00:00.000Z",
  };

  const createUserDto = {
    name: "Test Numone",
    email: "numone@test.com",
  };

  const updateUserDto = {
    name: "Test Numone update",
    email: "numoneupdate@test.com",
  };

  const userDtoResponse = {
    id: "test-uuid-123",
    name: "Test Numone",
    email: "numone@test.com",
  };

  const updatedUserResponse = {
    id: "test-uuid-123",
    name: "Test Numone update",
    email: "numoneupdate@test.com",
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,        {
          provide: DynamoDBService,
          useValue: {
            put: vi.fn().mockResolvedValue({ $metadata: {} }),
            get: vi.fn().mockResolvedValue({ Item: mockUser1, $metadata: {} }),
            scan: vi.fn().mockResolvedValue({ Items: [mockUser1, mockUser2], Count: 2, $metadata: {} }),
            update: vi.fn().mockResolvedValue({ 
              Attributes: {
                id: "test-uuid-123",
                name: "Test Numone update",
                email: "numoneupdate@test.com",
                updatedAt: "2024-01-01T00:00:00.000Z"
              },
              $metadata: {}
            }),
            delete: vi.fn().mockResolvedValue({ $metadata: {} }),
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    dynamoDBService = module.get<DynamoDBService>(DynamoDBService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("create", () => {
    it("should successfully add a user", async () => {
      const result = await service.create(createUserDto);
      
      expect(result).toEqual(userDtoResponse);
      expect(dynamoDBService.put).toHaveBeenCalledWith({
        id: "test-uuid-123",
        name: "Test Numone",
        email: "numone@test.com",
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      });
      expect(dynamoDBService.put).toHaveBeenCalledTimes(1);
    });
  });

  describe("findAll", () => {
    it("should return an array of users", async () => {
      const users = await service.findAll();
      
      expect(users).toEqual([
        { id: "test-uuid-123", name: "Test Numone", email: "numone@test.com" },
        { id: "test-uuid-456", name: "Test Numtwo", email: "numtwo@test.com" },
      ]);
      expect(dynamoDBService.scan).toHaveBeenCalledTimes(1);
    });
  });

  describe("findOne", () => {
    it("should get a single user", async () => {
      const user = await service.findOne("test-uuid-123");
      
      expect(user).toEqual(userDtoResponse);
      expect(dynamoDBService.get).toHaveBeenCalledWith({ id: "test-uuid-123" });
    });    it("should throw error when user not found", async () => {
      vi.spyOn(dynamoDBService, "get").mockResolvedValueOnce({ Item: undefined, $metadata: {} });
      
      await expect(service.findOne("non-existent-id")).rejects.toThrow("User with id non-existent-id not found");
    });
  });

  describe("update", () => {
    it("should call the update method", async () => {
      const user = await service.update("test-uuid-123", updateUserDto);
      
      expect(user).toEqual(updatedUserResponse);
      expect(dynamoDBService.update).toHaveBeenCalledWith(
        { id: "test-uuid-123" },
        "SET #name = :name, #email = :email, updatedAt = :updatedAt",
        {
          ":name": "Test Numone update",
          ":email": "numoneupdate@test.com",
          ":updatedAt": expect.any(String),
        },
        {
          "#name": "name",
          "#email": "email",
        }
      );
      expect(dynamoDBService.update).toHaveBeenCalledTimes(1);
    });
  });

  describe("remove", () => {
    it("should return {deleted: true}", async () => {
      const result = await service.remove("test-uuid-123");
      
      expect(result).toEqual({ deleted: true });
      expect(dynamoDBService.delete).toHaveBeenCalledWith({ id: "test-uuid-123" });
    });

    it("should return {deleted: false, message: err.message}", async () => {
      const mockError = new Error("Bad Delete Method.");
      vi.spyOn(dynamoDBService, "delete").mockRejectedValueOnce(mockError);
      
      const result = await service.remove("test-uuid-123");
      
      expect(result).toEqual({
        deleted: false,
        message: "Bad Delete Method.",
      });
      expect(dynamoDBService.delete).toHaveBeenCalledTimes(1);
    });
  });

  describe("searchUsers", () => {
    it("should return a list of users with pagination", async () => {
      const page = 1;
      const limit = 10;
      const sort = "{}";
      const filter = "{}";

      const result = await service.searchUsers(page, limit, sort, filter);

      expect(result).toEqual({
        users: [
          { id: "test-uuid-123", name: "Test Numone", email: "numone@test.com" },
          { id: "test-uuid-456", name: "Test Numtwo", email: "numtwo@test.com" },
        ],
        totalCount: 2,
        page: 1,
        limit: 10,
      });
      expect(dynamoDBService.scan).toHaveBeenCalledWith({ Limit: 10 });
    });

    it("given no page should return a list of users with default page 1", async () => {
      const limit = 10;
      const sort = "{}";
      const filter = "{}";

      const result = await service.searchUsers(null, limit, sort, filter);

      expect(result).toEqual({
        users: [
          { id: "test-uuid-123", name: "Test Numone", email: "numone@test.com" },
          { id: "test-uuid-456", name: "Test Numtwo", email: "numtwo@test.com" },
        ],
        totalCount: 2,
        page: 1,
        limit: 10,
      });
    });

    it("given no limit should return a list of users with default limit 10", async () => {
      const page = 1;
      const sort = "{}";
      const filter = "{}";

      const result = await service.searchUsers(page, null, sort, filter);

      expect(result).toEqual({
        users: [
          { id: "test-uuid-123", name: "Test Numone", email: "numone@test.com" },
          { id: "test-uuid-456", name: "Test Numtwo", email: "numtwo@test.com" },
        ],
        totalCount: 2,
        page: 1,
        limit: 10,
      });
    });

    it("given limit greater than 200 should return a list of users with default limit 10", async () => {
      const page = 1;
      const limit = 201;
      const sort = "{}";
      const filter = "{}";

      const result = await service.searchUsers(page, limit, sort, filter);

      expect(result).toEqual({
        users: [
          { id: "test-uuid-123", name: "Test Numone", email: "numone@test.com" },
          { id: "test-uuid-456", name: "Test Numtwo", email: "numtwo@test.com" },
        ],
        totalCount: 2,
        page: 1,
        limit: 10,
      });
    });
  });
});
