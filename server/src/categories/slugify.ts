export function slugify(name: string): string {
  if (!name) return '';

  let slug = name.toLowerCase().trim();

  slug = slug.normalize('NFD').replace(/[\u0300-\u036f]/g, '');

  slug = slug.replace(/[^a-z0-9\s-]/g, ' ').trim();

  slug = slug.replace(/[\s-]+/g, '-');

  slug = slug.replace(/^-+|-+$/g, '');

  return slug;
}
