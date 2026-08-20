import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '@/database/database.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { toVenue, Venue, VenueRow } from './entities/venue.entity';

const VENUE_COLUMNS = 'id, name, address, city, capacity, created_at';

@Injectable()
export class VenuesService {
  constructor(private readonly db: DatabaseService) {}

  async create(createVenueDto: CreateVenueDto): Promise<Venue> {
    const result = await this.db.query<VenueRow>(
      `INSERT INTO venues (name, address, city, capacity)
       VALUES ($1, $2, $3, $4)
       RETURNING ${VENUE_COLUMNS}`,
      [
        createVenueDto.name,
        createVenueDto.address,
        createVenueDto.city,
        createVenueDto.capacity,
      ],
    );

    return toVenue(result.rows[0]);
  }

  async findAll(): Promise<Venue[]> {
    const result = await this.db.query<VenueRow>(
      `SELECT ${VENUE_COLUMNS}
       FROM venues
       ORDER BY id`,
    );

    return result.rows.map(toVenue);
  }

  async findOne(id: number): Promise<Venue> {
    const result = await this.db.query<VenueRow>(
      `SELECT ${VENUE_COLUMNS}
       FROM venues
       WHERE id = $1`,
      [id],
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Venue with id ${id} not found`);
    }

    return toVenue(row);
  }

  async update(id: number, updateVenueDto: UpdateVenueDto): Promise<Venue> {
    const result = await this.db.query<VenueRow>(
      `UPDATE venues
       SET name     = COALESCE($2, name),
           address  = COALESCE($3, address),
           city     = COALESCE($4, city),
           capacity = COALESCE($5, capacity)
       WHERE id = $1
       RETURNING ${VENUE_COLUMNS}`,
      [
        id,
        updateVenueDto.name ?? null,
        updateVenueDto.address ?? null,
        updateVenueDto.city ?? null,
        updateVenueDto.capacity ?? null,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Venue with id ${id} not found`);
    }

    return toVenue(row);
  }

  async remove(id: number): Promise<void> {
    const result = await this.db.query(
      `DELETE FROM venues
       WHERE id = $1`,
      [id],
    );

    if (result.rowCount === 0) {
      throw new NotFoundException(`Venue with id ${id} not found`);
    }
  }
}
