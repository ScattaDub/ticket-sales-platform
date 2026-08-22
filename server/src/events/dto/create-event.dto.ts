import { EndsAfterStarts } from '../validators/ends-after-starts.validator';
import { EventFieldsDto } from './event-fields.dto';

@EndsAfterStarts()
export class CreateEventDto extends EventFieldsDto {}
