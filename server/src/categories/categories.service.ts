import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { DatabaseService } from '@/database/database.service';
import { Category, CategoryRow, toCategory } from './entities/category.entity';
import { slugify } from './slugify';

const CATEGORY_COLUMNS = 'id, name, slug';

@Injectable()
export class CategoriesService {
  constructor(private readonly db: DatabaseService) {}

  async create(createCategoryDto: CreateCategoryDto): Promise<Category> {
    const slug = slugify(createCategoryDto.name);

    if (!slug) {
      throw new BadRequestException([
        'name must contain at least one latin letter or digit',
      ]);
    }

    const result = await this.db.query<CategoryRow>(
      `INSERT INTO categories (name, slug)
       VALUES($1, $2)
       RETURNING ${CATEGORY_COLUMNS}`,
      [createCategoryDto.name, slugify(createCategoryDto.name)],
    );

    return toCategory(result.rows[0]);
  }

  async findAll(): Promise<Category[]> {
    const result = await this.db.query<CategoryRow>(
      `SELECT ${CATEGORY_COLUMNS}
       FROM categories
       ORDER BY id`,
    );

    return result.rows.map(toCategory);
  }

  async findOne(id: number): Promise<Category> {
    const result = await this.db.query<CategoryRow>(
      `SELECT ${CATEGORY_COLUMNS}
       FROM categories
       WHERE id = $1`,
      [id],
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Category with id ${id} not found`);
    }

    return toCategory(row);
  }

  async update(
    id: number,
    updateCategoryDto: UpdateCategoryDto,
  ): Promise<Category> {
    const result = await this.db.query<CategoryRow>(
      `UPDATE categories
       SET name = COALESCE($2, name)
       WHERE id = $1
       RETURNING ${CATEGORY_COLUMNS}`,
      [id, updateCategoryDto.name],
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Category with id ${id} not found`);
    }

    return toCategory(row);
  }

  async remove(id: number): Promise<void> {
    const result = await this.db.query(
      `DELETE FROM categories
       WHERE id = $1`,
      [id],
    );

    if (result.rowCount === 0) {
      throw new NotFoundException(`Category with id ${id} not found`);
    }
  }
}
