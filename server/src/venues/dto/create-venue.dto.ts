import { IsInt, IsString, MaxLength, Min, MinLength } from 'class-validator';

export class CreateVenueDto {
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  name!: string;

  @IsString()
  @MinLength(1)
  address!: string;

  @IsString()
  @MinLength(1)
  city!: string;

  @IsInt()
  @Min(1)
  capacity!: number;
}
