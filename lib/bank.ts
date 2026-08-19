import { supabase } from '@/lib/supabase/client'
import type { BankSummary } from '@/lib/bank-statements'

/**
 * Bank statement-summary store using Supabase.
 * Holds per-business monthly income/outflow, not transactions.
 */

export type BankStore = {
  upsert(summary: BankSummary): Promise<void>;
  all(): Promise<BankSummary[]>;
  close(): Promise<void>;
};

export async function openBankStore(): Promise<BankStore> {
  const upsert = async (summary: BankSummary) => {
    const { error } = await supabase
      .from('bank_summaries')
      .upsert({
        account: summary.account,
        business: summary.business,
        month: summary.month,
        credits_cents: summary.creditsCents,
        debits_cents: summary.debitsCents,
        net_cents: summary.netCents,
      }, {
        onConflict: ['account', 'month']
      })
    if (error) throw error
  }

  const all = async (): Promise<BankSummary[]> => {
    const { data, error } = await supabase
      .from('bank_summaries')
      .select('*')
      .order('month', { ascending: true })
      .order('business', { ascending: true })
    if (error) throw error
    return data?.map(row => ({
      account: row.account,
      business: row.business,
      month: row.month,
      creditsCents: row.credits_cents,
      debitsCents: row.debits_cents,
      netCents: row.net_cents,
    })) ?? []
  }

  const close = async () => {
    // No-op for Supabase
  }

  return { upsert, all, close }
}