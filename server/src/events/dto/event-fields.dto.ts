import { IsIsoInstant } from '@/common/validators/is-iso-instant.validator';
import {
  IsNumberString,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class EventFieldsDto {
  @IsNumberString({ no_symbols: true })
  organizerId!: string;

  @IsNumberString({ no_symbols: true })
  venueId!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string | null;

  @IsIsoInstant()
  startsAt!: string;

  @IsIsoInstant()
  endsAt!: string;
}
