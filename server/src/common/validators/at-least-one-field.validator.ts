import {
  registerDecorator,
  ValidationArguments,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

@ValidatorConstraint({ name: 'atLeastOneField', async: false })
class AtLeastOneFieldConstraint implements ValidatorConstraintInterface {
  validate(value: unknown, args: ValidationArguments): boolean {
    return Object.values(args.object).some((v) => v !== undefined);
  }

  defaultMessage(): string {
    return 'Body should not be empty';
  }
}

export function AtLeastOneField(options?: ValidationOptions): ClassDecorator {
  return (target) => {
    registerDecorator({
      target,
      validator: AtLeastOneFieldConstraint,
      propertyName: undefined as unknown as string,
      options,
    });
  };
}
