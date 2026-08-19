import { db } from '@/lib/db-supabase'

/**
 * App-level singleton. Real-ready: every page and API route reads
 * through this Supabase database.
 */
let instance: ReturnType<typeof db> | null = null

export function getDb() {
  if (instance) return instance
  instance = db
  return instance
}