export type CategoryRow = {
  id: string;
  name: string;
  slug: string;
};

export interface Category {
  id: string;
  name: string;
  slug: string;
}

export function toCategory(row: CategoryRow): Category {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
  };
}
