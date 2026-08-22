import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { DatabaseService } from '@/database/database.service';
import { Event, EventRow, toEvent } from './entities/event.entity';

const EVENT_COLUMNS =
  'id, organizer_id, venue_id, title, description, status, starts_at, ends_at, published_at, created_at, updated_at';

const UPDATABLE_COLUMNS = {
  organizerId: 'organizer_id',
  venueId: 'venue_id',
  title: 'title',
  description: 'description',
  startsAt: 'starts_at',
  endsAt: 'ends_at',
  status: 'status',
} as const;

type UpdatableField = keyof typeof UPDATABLE_COLUMNS;

@Injectable()
export class EventsService {
  constructor(private readonly db: DatabaseService) {}

  async create(createEventDto: CreateEventDto): Promise<Event> {
    const result = await this.db.query<EventRow>(
      `INSERT INTO events (organizer_id, venue_id, title, description, starts_at, ends_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING ${EVENT_COLUMNS}
      `,
      [
        createEventDto.organizerId,
        createEventDto.venueId,
        createEventDto.title,
        createEventDto.description,
        createEventDto.startsAt,
        createEventDto.endsAt,
      ],
    );

    return toEvent(result.rows[0]);
  }

  async findAll(): Promise<Event[]> {
    const result = await this.db.query<EventRow>(
      `SELECT ${EVENT_COLUMNS}
       FROM events
       ORDER BY id
      `,
    );

    return result.rows.map(toEvent);
  }

  async findOne(id: number): Promise<Event> {
    const result = await this.db.query<EventRow>(
      `SELECT ${EVENT_COLUMNS}
       FROM events
       WHERE id = $1
      `,
      [id],
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Event with id ${id} not found`);
    }

    return toEvent(row);
  }

  async update(id: number, updateEventDto: UpdateEventDto): Promise<Event> {
    const assignments: string[] = [];
    const params: unknown[] = [id];

    for (const [field, column] of Object.entries(UPDATABLE_COLUMNS) as [
      UpdatableField,
      string,
    ][]) {
      const value = updateEventDto[field];
      if (value === undefined) continue;

      params.push(value);
      assignments.push(`${column} = $${params.length}`);
    }

    if (updateEventDto.status === 'published') {
      assignments.push(`published_at = COALESCE(published_at, now())`);
    }

    assignments.push('updated_at = now()');

    const result = await this.db.query<EventRow>(
      `UPDATE events
       SET ${assignments.join(', ')}
       WHERE id = $1
       RETURNING ${EVENT_COLUMNS}`,
      params,
    );

    const row = result.rows[0];

    if (!row) {
      throw new NotFoundException(`Event with id ${id} not found`);
    }

    return toEvent(row);
  }

  async remove(id: number): Promise<void> {
    const result = await this.db.query(
      `DELETE FROM events
       WHERE id = $1
      `,
      [id],
    );

    if (result.rowCount === 0) {
      throw new NotFoundException(`Event with id ${id} not found`);
    }
  }
}
