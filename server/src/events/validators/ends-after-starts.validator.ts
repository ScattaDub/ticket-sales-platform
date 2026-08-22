import {
  registerDecorator,
  ValidationArguments,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

type PeriodFields = { startsAt?: unknown; endsAt?: unknown };

@ValidatorConstraint({ name: 'endsAfterStarts', async: false })
class EndsAfterStartsConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    const { startsAt, endsAt } = args.object as PeriodFields;

    if (startsAt === undefined && endsAt === undefined) return true;
    if (typeof startsAt !== 'string' || typeof endsAt !== 'string')
      return false;

    const from = Date.parse(startsAt);
    const to = Date.parse(endsAt);
    if (Number.isNaN(from) || Number.isNaN(to)) return true;

    return to > from;
  }

  defaultMessage(args: ValidationArguments): string {
    const { startsAt, endsAt } = args.object as PeriodFields;
    if (typeof startsAt !== 'string' || typeof endsAt !== 'string') {
      return 'startsAt and endsAt must be provided together';
    }
    return 'endsAt must be later than startsAt';
  }
}

export function EndsAfterStarts(options?: ValidationOptions): ClassDecorator {
  return (target) => {
    registerDecorator({
      target,
      propertyName: undefined as unknown as string,
      options,
      validator: EndsAfterStartsConstraint,
    });
  };
}
