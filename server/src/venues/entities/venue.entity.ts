export type VenueRow = {
  id: string;
  name: string;
  address: string;
  city: string;
  capacity: number;
  created_at: Date;
};

export interface Venue {
  id: string;
  name: string;
  address: string;
  city: string;
  capacity: number;
  createdAt: Date;
}

export function toVenue(row: VenueRow): Venue {
  return {
    id: row.id,
    name: row.name,
    address: row.address,
    city: row.city,
    capacity: row.capacity,
    createdAt: row.created_at,
  };
}
