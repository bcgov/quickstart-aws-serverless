import { ApiProperty } from '@nestjs/swagger';

export class UserDto {
  @ApiProperty({
    description: 'The ID of the user',
    example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  })
  id: string;

  @ApiProperty({
    description: 'The name of the user',
    // default: 'username',
  })
  name: string;

  @ApiProperty({
    description: 'The contact email of the user',
    default: '',
  })
  email: string;
}
