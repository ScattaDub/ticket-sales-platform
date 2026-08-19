import { PartialType } from '@nestjs/mapped-types';
import { CreateCategoryDto } from './create-category.dto';
import { AtLeastOneField } from '@/common/validators/at-least-one-field.validator';

@AtLeastOneField()
export class UpdateCategoryDto extends PartialType(CreateCategoryDto) {}
