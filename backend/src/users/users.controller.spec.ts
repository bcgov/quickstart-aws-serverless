import { Test, TestingModule } from "@nestjs/testing";
import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";
import request from "supertest";
import { HttpException, INestApplication } from "@nestjs/common";
import { CreateUserDto } from "./dto/create-user.dto";
import { UpdateUserDto } from "./dto/update-user.dto";
import { UserDto } from "./dto/user.dto";
import { DynamoDBService } from "src/dynamodb.service";

describe("UserController", () => {
  let controller: UsersController;
  let usersService: UsersService;
  let app: INestApplication;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        UsersService,
        {
          provide: DynamoDBService,
          useValue: {
            put: vi.fn(),
            get: vi.fn(),
            scan: vi.fn(),
            update: vi.fn(),
            delete: vi.fn(),
          },
        },
      ],
    }).compile();
    usersService = module.get<UsersService>(UsersService);
    controller = module.get<UsersController>(UsersController);
    app = module.createNestApplication();
    await app.init();
  });

  // Close the app after each test
  afterEach(async () => {
    await app.close();
  });

  it("should be defined", () => {
    expect(controller).toBeDefined();
  });

  describe("create", () => {
    it("should call the service create method with the given dto and return the result", async () => {
      // Arrange
      const createUserDto: CreateUserDto = {
        email: "test@example.com",
        name: "Test User",
      };
      const expectedResult = {
        id: "test-uuid-123",
        ...createUserDto,
      };
      vi.spyOn(usersService, "create").mockResolvedValue(expectedResult);

      // Act
      const result = await controller.create(createUserDto);

      // Assert
      expect(usersService.create).toHaveBeenCalledWith(createUserDto);
      expect(result).toEqual(expectedResult);
    });
  });  describe("findAll", () => {
    it("should return an array of users", async () => {
      const result = [];
      result.push({ id: "test-uuid-1", name: "Alice", email: "test@gmail.com" });
      vi.spyOn(usersService, "findAll").mockResolvedValue(result);
      expect(await controller.findAll()).toBe(result);
    });
  });

  describe("findOne", () => {
    it("should return a user object", async () => {
      const result: UserDto = {
        id: "test-uuid-1",
        name: "john",
        email: "John_Doe@gmail.com",
      };
      vi.spyOn(usersService, "findOne").mockResolvedValue(result);
      expect(await controller.findOne("test-uuid-1")).toBe(result);
    });

    it("should throw error if user not found", async () => {
      vi.spyOn(usersService, "findOne").mockResolvedValue(undefined);
      try {
        await controller.findOne("test-uuid-1");
      } catch (e) {
        expect(e).toBeInstanceOf(HttpException);
        expect(e.message).toBe("User not found.");
      }
    });
  });

  describe("update", () => {
    it("should update and return a user object", async () => {
      const id = "test-uuid-1";
      const updateUserDto: UpdateUserDto = {
        email: "johndoe@example.com",
        name: "John Doe",
      };
      const userDto: UserDto = {
        id: "test-uuid-1",
        name: "John Doe",
        email: "johndoe@example.com",
      };      vi.spyOn(usersService, "update").mockResolvedValue(userDto);

      expect(await controller.update(id, updateUserDto)).toBe(userDto);
      expect(usersService.update).toHaveBeenCalledWith(id, updateUserDto);
    });
  });

  describe("remove", () => {
    it("should remove a user", async () => {
      const id = "test-uuid-1";
      vi.spyOn(usersService, "remove").mockResolvedValue(undefined);

      expect(await controller.remove(id)).toBeUndefined();
      expect(usersService.remove).toHaveBeenCalledWith(id);
    });
  });
  // Test the GET /users/search endpoint
  describe("GET /users/search", () => {
    // Test with valid query parameters
    it("given valid query parameters_should return an array of users with pagination metadata", async () => {      // Mock the usersService.searchUsers method to return a sample result
      const result = {
        users: [
          { id: "test-uuid-1", name: "Alice", email: "alice@example.com" },
          { id: "test-uuid-2", name: "Adam", email: "Adam@example.com" },
        ],
        totalCount: 2,
        page: 1,
        limit: 10,
      };
      vi.spyOn(usersService, "searchUsers").mockImplementation(
        async () => result,
      );

      // Make a GET request with query parameters and expect a 200 status code and the result object
      return request(app.getHttpServer())
        .get("/users/search")        .query({
          page: 1,
          limit: 10,
          sort: '{}',
          filter: '{}',
        })
        .expect(200)
        .expect(result);
    });

    // Test with invalid query parameters
    it("given invalid query parameters_should return a 400 status code with an error message", async () => {
      // Make a GET request with invalid query parameters and expect a 400 status code and an error message
      return request(app.getHttpServer())
        .get("/users/search")
        .query({
          page: "invalid",
          limit: "invalid",
        })
        .expect(400)
        .expect({
          statusCode: 400,
          message: "Invalid query parameters",
        });
    });
    it("given sort and filter as invalid query parameters_should return a 400 status code with an error message", async () => {
      // Make a GET request with invalid query parameters and expect a 400 status code and an error message
      vi.spyOn(usersService, "searchUsers").mockImplementation(async () => {
        throw new HttpException("Invalid query parameters", 400);
      });
      return request(app.getHttpServer())
        .get("/users/search")
        .query({
          page: 1,
          limit: 10,
          sort: "invalid",
          filter: "invalid",
        })
        .expect(400)
        .expect({
          statusCode: 400,
          message: "Invalid query parameters",
        });
    });
  });
});
