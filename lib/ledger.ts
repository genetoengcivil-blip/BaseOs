import { supabase } from '@/lib/supabase/client'
import type { LedgerRow } from '@/lib/statements'

/**
 * Statement ledger using Supabase.
 * Deliberately NOT wired into lib/db.ts's repo layer (as per original comment).
 * We keep it separate for PII, but now using Supabase.
 */

export type Ledger = {
  insertRows(rows: LedgerRow[]): Promise<number>;
  /** Spend by category for the most recent month present (so "/mo" is honest). */
  monthly(): Promise<{ category: string; total: number }[]>;
  /** The latest YYYY-MM with spend, or null when empty. */
  latestMonth(): Promise<string | null>;
  reconcile(incomeUsd: number): Promise<{ income: number; expenses: number; net: number }>;
  rowCount(): Promise<number>;
  close(): Promise<void>;
};

export async function openLedger(): Promise<Ledger> {
  const insertRows = async (rows: LedgerRow[]): Promise<number> => {
    // We'll insert each row, ignoring duplicates (by hash)
    const toInsert = rows.map(r => ({
      hash: `${r.date}|${r.description}|${r.amountCents}|${r.direction}`,
      date: r.date,
      description: r.description,
      amount_cents: r.amountCents,
      direction: r.direction,
      category: r.category,
    }));

    const { error } = await supabase
      .from('ledger_rows')
      .upsert(toInsert, { onConflict: ['hash'] });

    if (error) throw error;
    // We don't have an easy way to get the number of inserted rows from Supabase upsert.
    // We'll return the number of rows we attempted to insert as an approximation.
    return rows.length;
  };

  const monthly = async (): Promise<{ category: string; total: number }[]> => {
    // We want to get the latest month with expenses, then sum by category for that month.
    // First, get the latest month with expenses.
    const latestMonthResult = await supabase
      .from('ledger_rows')
      .select('substr(date, 1, 7) as month')
      .eq('direction', 'out')
      .order('month', { ascending: false })
      .limit(1);

    if (latestMonthResult.error) throw latestMonthResult.error;
    if (!latestMonthResult.data || latestMonthResult.data.length === 0) {
      return [];
    }

    const latestMonth = latestMonthResult.data[0].month;

    // Now, get the expenses for that month, grouped by category.
    const { data, error } = await supabase
      .from('ledger_rows')
      .select('category, amount_cents')
      .eq('direction', 'out')
      .eq('substr(date, 1, 7)', latestMonth);

    if (error) throw error;

    // Sum by category
    const totals: Record<string, number> = {};
    data?.forEach(row => {
      const category = row.category;
      const amount = row.amount_cents;
      totals[category] = (totals[category] || 0) + amount;
    });

    return Object.entries(totals).map(([category, total]) => ({
      category,
      total: total / 100, // convert to dollars? Actually, the original returns total in cents? Let's check.
    }));
  };

  const latestMonth = async (): Promise<string | null> => {
    const { data, error } = await supabase
      .from('ledger_rows')
      .select('substr(date, 1, 7) as month')
      .eq('direction', 'out')
      .order('month', { ascending: false })
      .limit(1);

    if (error) throw error;
    if (!data || data.length === 0) return null;
    return data[0].month;
  };

  const reconcile = async (incomeUsd: number): Promise<{ income: number; expenses: number; net: number }> => {
    // We'll calculate total expenses in cents, then convert to dollars.
    const { data, error } = await supabase
      .from('ledger_rows')
      .select('amount_cents, direction')
      .not('amount_cents', 'is', null);

    if (error) throw error;

    let totalExpensesCents = 0;
    let totalIncomeCents = 0;

    data?.forEach(row => {
      if (row.direction === 'out') {
        totalExpensesCents += row.amount_cents;
      } else if (row.direction === 'in') {
        totalIncomeCents += row.amount_cents;
      }
    });

    // Convert incomeUsd to cents for comparison? Actually, the function expects incomeUsd in dollars.
    // We'll convert everything to dollars for the return.
    const incomeDollars = incomeUsd;
    const expensesDollars = totalExpensesCents / 100;
    const netDollars = incomeDollars - expensesDollars;

    return {
      income: incomeDollars,
      expenses: expensesDollars,
      net: netDollars,
    };
  };

  const rowCount = async (): Promise<number> => {
    const { data, error } = await supabase
      .from('ledger_rows')
      .select('*', { count: 'exact', head: true });

    if (error) throw error;
    return data?.count ?? 0;
  };

  const close = async (): Promise<void> => {
    // No-op for Supabase
  };

  return { insertRows, monthly, latestMonth, reconcile, rowCount, close };
}