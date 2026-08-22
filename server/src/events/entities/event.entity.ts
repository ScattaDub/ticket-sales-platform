export const EVENT_STATUSES = [
  'draft',
  'published',
  'cancelled',
  'completed',
] as const;

export type EventStatus = (typeof EVENT_STATUSES)[number];

export type EventRow = {
  id: string;
  organizer_id: string;
  venue_id: string;
  title: string;
  description: string | null;
  status: EventStatus;
  starts_at: Date;
  ends_at: Date;
  published_at: Date | null;
  created_at: Date;
  updated_at: Date;
};

export interface Event {
  id: string;
  organizerId: string;
  venueId: string;
  title: string;
  description: string | null;
  status: EventStatus;
  startsAt: Date;
  endsAt: Date;
  publishedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export function toEvent(row: EventRow): Event {
  return {
    id: row.id,
    organizerId: row.organizer_id,
    venueId: row.venue_id,
    title: row.title,
    description: row.description,
    status: row.status,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    publishedAt: row.published_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
