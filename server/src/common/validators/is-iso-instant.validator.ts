import { applyDecorators } from '@nestjs/common';
import { IsISO8601, Matches } from 'class-validator';

const ISO_INSTANT =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:\d{2})$/;

export function IsIsoInstant(): PropertyDecorator {
  return applyDecorators(
    IsISO8601({ strict: true }),
    Matches(ISO_INSTANT, {
      message:
        '$property must be an ISO 8601 instant with a timezone offset, e.g. 2026-09-01T19:00:00Z',
    }),
  );
}
