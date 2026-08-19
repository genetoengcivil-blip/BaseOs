import { NextResponse } from 'next/server';
import { getDb } from '@/lib/data';

export const dynamic = 'force-dynamic';

export async function GET() {
  const db = getDb();
  const agents = await db.agents.all();
  return NextResponse.json({ agents });
}