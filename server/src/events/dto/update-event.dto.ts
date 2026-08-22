import { AtLeastOneField } from '@/common/validators/at-least-one-field.validator';
import { EndsAfterStarts } from '../validators/ends-after-starts.validator';
import { IsIn, IsOptional } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';
import { EventFieldsDto } from './event-fields.dto';
import { EVENT_STATUSES, type EventStatus } from '../entities/event.entity';

@AtLeastOneField()
@EndsAfterStarts()
export class UpdateEventDto extends PartialType(EventFieldsDto) {
  @IsOptional()
  @IsIn(EVENT_STATUSES)
  status?: EventStatus;
}
