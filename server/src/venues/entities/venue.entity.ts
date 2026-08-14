/**
 * A row exactly as Postgres hands it back: snake_case column names, and `id`
 * as a string — node-postgres never narrows bigint to a JS number, because
 * int8 goes up to 2^63 while Number is only exact up to 2^53.
 *
 * Declared as a type alias rather than an interface on purpose: pg constrains
 * the row type to `{ [column: string]: any }`, and only type aliases get an
 * implicit index signature in TypeScript. An interface here fails to compile.
 */
export type VenueRow = {
  id: string;
  name: string;
  address: string;
  city: string;
  capacity: number;
  created_at: Date;
};

/** The shape the API exposes: camelCase, and only what clients may see. */
export interface Venue {
  id: string;
  name: string;
  address: string;
  city: string;
  capacity: number;
  createdAt: Date;
}

/**
 * The single place where the database shape becomes the API shape.
 * Keeping it in one function makes new columns opt-in: a column added to the
 * table stays invisible to clients until it is mapped here deliberately.
 */
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
