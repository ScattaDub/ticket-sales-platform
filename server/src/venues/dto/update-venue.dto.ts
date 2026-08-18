import { PartialType } from '@nestjs/mapped-types';
import { CreateVenueDto } from './create-venue.dto';
import { AtLeastOneField } from '@/common/validators/at-least-one-field.validator';

@AtLeastOneField()
export class UpdateVenueDto extends PartialType(CreateVenueDto) {}
