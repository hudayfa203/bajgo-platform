import { z } from 'zod';

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
  sort: z.string().optional(),
  q: z.string().optional(),
});
export type Pagination = z.infer<typeof paginationSchema>;

export function paginated<T>(data: T[], meta: { page: number; limit: number; total: number }) {
  return { data, meta };
}

export function parseSort(sort: string | undefined, allowed: string[], fallback = '-created_at'): { column: string; dir: 'asc' | 'desc' } {
  const s = sort && allowed.includes(sort.replace(/^-/, '')) ? sort : fallback;
  return { column: s.replace(/^-/, ''), dir: s.startsWith('-') ? 'desc' : 'asc' };
}
