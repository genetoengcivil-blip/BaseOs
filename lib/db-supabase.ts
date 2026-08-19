import { supabase } from '@/lib/supabase/client'
import {
  DepartmentSchema,
  type Department,
  AgentSchema,
  type Agent,
  ToolSchema,
  type Tool,
  RoadmapItemSchema,
  type RoadmapItem,
  MetricSchema,
  type Metric,
  DomainSchema,
  type Domain,
  PersonaSchema,
  type Persona,
  PhaseSchema,
  type Phase,
  AgentRunSchema,
  type AgentRun,
  AgentMessageSchema,
  type AgentMessage,
  BroadcastSchema,
  type Broadcast,
  BroadcastReplySchema,
  type BroadcastReply,
  AgentTaskSchema,
  type AgentTask,
  AgentCronSchema,
  type AgentCron,
  ContactTagSchema,
  type ContactTag,
  SocialAccountSchema,
  type SocialAccount,
  SocialSnapshotSchema,
  type SocialSnapshot,
  SocialDmSchema,
  type SocialDm,
  SocialDmSnapshotSchema,
  type SocialDmSnapshot,
  SocialDmMessageSchema,
  type SocialDmMessage,
  SocialPostSchema,
  type SocialPost,
  PersonSchema,
  type Person,
  LeadMagnetSchema,
  type LeadMagnet,
  SopTaskSchema,
  type SopTask,
  WorkflowSchema,
  type Workflow,
  SkillSchema,
  type Skill,
  FunnelContactSchema,
  type FunnelContact,
  FunnelTouchSchema,
  type FunnelTouch,
  FunnelJourneySchema,
  type FunnelJourney,
  EmailListSnapshotSchema,
  type EmailListSnapshot,
} from '@/lib/schemas'
import { v4 as uuidv4 } from 'uuid'

// Helper to generate UUID
const generateId = () => uuidv4()

// Helper to handle Supabase errors
const handleError = (error: any) => {
  if (error) throw error
}

// Departments
export const departments = {
  async all(): Promise<Department[]> {
    const { data, error } = await supabase
      .from('departments')
      .select('*')
      .order('order')
    handleError(error)
    return data ? data.map((d) => DepartmentSchema.parse(d)) : []
  },
  async insert(d: Department): Promise<void> {
    const { error } = await supabase
      .from('departments')
      .insert({ ...d, id: d.id || generateId() })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('departments')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Agents
export const agents = {
  async all(): Promise<Agent[]> {
    const { data, error } = await supabase
      .from('agents')
      .select('*')
      .order('tier, name')
    handleError(error)
    return data ? data.map((a) => AgentSchema.parse(a)) : []
  },
  async byDepartment(departmentId: string): Promise<Agent[]> {
    const { data, error } = await supabase
      .from('agents')
      .select('*')
      .eq('department_id', departmentId)
      .order('tier, name')
    handleError(error)
    return data ? data.map((a) => AgentSchema.parse(a)) : []
  },
  async insert(a: Agent): Promise<void> {
    const { error } = await supabase
      .from('agents')
      .insert({ ...a, id: a.id || generateId() })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('agents')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Tools
export const tools = {
  async all(): Promise<Tool[]> {
    const { data, error } = await supabase
      .from('tools')
      .select('*')
      .order('category, name')
    handleError(error)
    return data ? data.map((t) => ToolSchema.parse(t)) : []
  },
  async insert(t: Tool): Promise<void> {
    const { error } = await supabase
      .from('tools')
      .insert({ ...t, id: t.id || generateId() })
    handleError(error)
  },
}

// Roadmap
export const roadmap = {
  async all(): Promise<RoadmapItem[]> {
    const { data, error } = await supabase
      .from('roadmap_items')
      .select('*')
      .order('quarter, title')
    handleError(error)
    return data ? data.map((r) => RoadmapItemSchema.parse(r)) : []
  },
  async insert(item: RoadmapItem): Promise<void> {
    const { error } = await supabase
      .from('roadmap_items')
      .insert({ ...item, id: item.id || generateId() })
    handleError(error)
  },
}

// Metrics
export const metrics = {
  async all(): Promise<Metric[]> {
    const { data, error } = await supabase
      .from('metrics')
      .select('*')
      .order('label')
    handleError(error)
    return data ? data.map((m) => MetricSchema.parse(m)) : []
  },
  async insert(m: Metric): Promise<void> {
    const { error } = await supabase
      .from('metrics')
      .insert({ ...m, id: m.id || generateId() })
    handleError(error)
  },
}

// Domains
export const domains = {
  async all(): Promise<Domain[]> {
    const { data, error } = await supabase
      .from('domains')
      .select('*')
      .order('number')
    handleError(error)
    return data ? data.map((d) => DomainSchema.parse({ ...d, items: JSON.parse(d.items) })) : []
  },
  async insert(d: Domain): Promise<void> {
    const { error } = await supabase
      .from('domains')
      .insert({ ...d, id: d.id || generateId(), items: JSON.stringify(d.items) })
    handleError(error)
  },
}

// Personas
export const personas = {
  async all(): Promise<Persona[]> {
    const { data, error } = await supabase
      .from('personas')
      .select('*')
      .order('ord')
    handleError(error)
    return data ? data.map((p) => {
      const parsed = {
        ...p,
        pillars: JSON.parse(p.pillars),
        connectors: JSON.parse(p.connectors),
        metrics: JSON.parse(p.metrics),
      }
      return PersonaSchema.parse(parsed)
    }) : []
  },
  async insert(p: Persona): Promise<void> {
    const { error } = await supabase
      .from('personas')
      .insert({
        ...p,
        id: p.id || generateId(),
        pillars: JSON.stringify(p.pillars),
        connectors: JSON.stringify(p.connectors),
        metrics: JSON.stringify(p.metrics),
      })
    handleError(error)
  },
}

// Phases
export const phases = {
  async all(): Promise<Phase[]> {
    const { data, error } = await supabase
      .from('phases')
      .select('*')
      .order('number')
    handleError(error)
    return data ? data.map((p) => PhaseSchema.parse({ ...p, items: JSON.parse(p.items) })) : []
  },
  async insert(p: Phase): Promise<void> {
    const { error } = await supabase
      .from('phases')
      .insert({ ...p, id: p.id || generateId(), items: JSON.stringify(p.items) })
    handleError(error)
  },
}

// Agent Runs
export const agentRuns = {
  async byAgent(agentId: string): Promise<AgentRun[]> {
    const { data, error } = await supabase
      .from('agent_runs')
      .select('*')
      .eq('agent_id', agentId)
      .order('started_at', { ascending: false })
    handleError(error)
    return data ? data.map((r) => AgentRunSchema.parse(r)) : []
  },
  async recent(limit: number): Promise<AgentRun[]> {
    const { data, error } = await supabase
      .from('agent_runs')
      .select('*')
      .order('started_at', { ascending: false })
      .limit(limit)
    handleError(error)
    return data ? data.map((r) => AgentRunSchema.parse(r)) : []
  },
  async insert(run: AgentRun): Promise<void> {
    const { error } = await supabase
      .from('agent_runs')
      .insert({ ...run, id: run.id || generateId() })
    handleError(error)
  },
}

// Agent Messages
export const agentMessages = {
  async insert(m: AgentMessage): Promise<void> {
    const { error } = await supabase
      .from('agent_messages')
      .insert({ ...m, id: m.id || generateId(), tool_calls: JSON.stringify(m.toolCalls) })
    handleError(error)
  },
  async byAgent(agentId: string): Promise<AgentMessage[]> {
    const { data, error } = await supabase
      .from('agent_messages')
      .select('*')
      .eq('agent_id', agentId)
      .order('created_at', { ascending: true })
    handleError(error)
    return data ? data.map((m) => AgentMessageSchema.parse({ ...m, toolCalls: JSON.parse(m.tool_calls || '[]') })) : []
  },
  async recent(limit: number): Promise<AgentMessage[]> {
    const { data, error } = await supabase
      .from('agent_messages')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    handleError(error)
    return data ? data.map((m) => AgentMessageSchema.parse({ ...m, toolCalls: JSON.parse(m.tool_calls || '[]') })) : []
  },
}

// Broadcasts
export const broadcasts = {
  async insert(b: { id: string; message: string; createdAt: string }): Promise<void> {
    const { error } = await supabase
      .from('broadcasts')
      .insert({ ...b, id: b.id || generateId() })
    handleError(error)
  },
  async insertReply(r: BroadcastReply): Promise<void> {
    const { error } = await supabase
      .from('broadcast_replies')
      .insert({ ...r, id: r.id || generateId() })
    handleError(error)
  },
  async recent(limit: number): Promise<Broadcast[]> {
    // We need to fetch broadcasts and their replies
    const { data: broadcastData, error: broadcastError } = await supabase
      .from('broadcasts')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    handleError(broadcastError)
    if (!broadcastData) return []

    // For each broadcast, fetch replies
    const broadcastsWithReplies = await Promise.all(
      broadcastData.map(async (b) => {
        const { data: replyData, error: replyError } = await supabase
          .from('broadcast_replies')
          .select('*')
          .eq('broadcast_id', b.id)
          .order('agent_id')
        handleError(replyError)
        return {
          ...b,
          replies: replyData ? replyData.map((r) => BroadcastReplySchema.parse(r)) : [],
        }
      })
    )

    return broadcastsWithReplies.map((b) =>
      BroadcastSchema.parse({
        ...b,
        replies: b.replies,
      })
    )
  },
}

// Agent Tasks
export const agentTasks = {
  async insert(t: AgentTask): Promise<void> {
    const { error } = await supabase
      .from('agent_tasks')
      .insert({ ...t, id: t.id || generateId() })
    handleError(error)
  },
  async byAgent(agentId: string): Promise<AgentTask[]> {
    const { data, error } = await supabase
      .from('agent_tasks')
      .select('*')
      .eq('agent_id', agentId)
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((t) => AgentTaskSchema.parse(t)) : []
  },
  async all(): Promise<AgentTask[]> {
    const { data, error } = await supabase
      .from('agent_tasks')
      .select('*')
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((t) => AgentTaskSchema.parse(t)) : []
  },
  async setStatus(id: string, status: AgentTask['status'], updatedAt: string): Promise<void> {
    const { error } = await supabase
      .from('agent_tasks')
      .update({ status, updated_at: updatedAt })
      .eq('id', id)
    handleError(error)
  },
  async remove(id: string): Promise<void> {
    const { error } = await supabase
      .from('agent_tasks')
      .delete()
      .eq('id', id)
    handleError(error)
  },
}

// Agent Crons
export const agentCrons = {
  async insert(c: AgentCron): Promise<void> {
    // Note: We assume cron validation is done elsewhere
    const { error } = await supabase
      .from('agent_crons')
      .insert({ ...c, id: c.id || generateId() })
    handleError(error)
  },
  async byAgent(agentId: string): Promise<AgentCron[]> {
    const { data, error } = await supabase
      .from('agent_crons')
      .select('*')
      .eq('agent_id', agentId)
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((c) => AgentCronSchema.parse(c)) : []
  },
  async all(): Promise<AgentCron[]> {
    const { data, error } = await supabase
      .from('agent_crons')
      .select('*')
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((c) => AgentCronSchema.parse(c)) : []
  },
  async setEnabled(id: string, enabled: boolean): Promise<void> {
    const { error } = await supabase
      .from('agent_crons')
      .update({ enabled: enabled ? 1 : 0 })
      .eq('id', id)
    handleError(error)
  },
  async remove(id: string): Promise<void> {
    const { error } = await supabase
      .from('agent_crons')
      .delete()
      .eq('id', id)
    handleError(error)
  },
}

// Contact Tags
export const contactTags = {
  async upsert(t: ContactTag): Promise<void> {
    const { error } = await supabase
      .from('contact_tags')
      .upsert(
        { ...t, id: `${t.person}-${t.channel}` }, // Using composite key as id for upsert
        { onConflict: ['person', 'channel'] }
      )
    handleError(error)
  },
  async all(): Promise<ContactTag[]> {
    const { data, error } = await supabase
      .from('contact_tags')
      .select('*')
      .order('tier, person')
    handleError(error)
    return data ? data.map((r) => ContactTagSchema.parse(r)) : []
  },
  async byTier(tier: number): Promise<ContactTag[]> {
    const { data, error } = await supabase
      .from('contact_tags')
      .select('*')
      .eq('tier', tier)
      .order('person')
    handleError(error)
    return data ? data.map((r) => ContactTagSchema.parse(r)) : []
  },
  async remove(person: string, channel: string): Promise<void> {
    const { error } = await supabase
      .from('contact_tags')
      .delete()
      .eq('person', person)
      .eq('channel', channel)
    handleError(error)
  },
}

// Social
export const social = {
  async upsertAccount(a: SocialAccount): Promise<void> {
    const { error } = await supabase
      .from('social_accounts')
      .upsert({ ...a, platform: a.platform }, { onConflict: ['platform'] })
    handleError(error)
  },
  async accounts(): Promise<SocialAccount[]> {
    const { data, error } = await supabase
      .from('social_accounts')
      .select('*')
      .order('"order"')
    handleError(error)
    return data ? data.map((r) => SocialAccountSchema.parse(r)) : []
  },
  async insertSnapshot(s: SocialSnapshot): Promise<void> {
    const { error } = await supabase
      .from('social_snapshots')
      .insert({ ...s, id: `${s.platform}-${s.capturedAt}` }, { onConflict: ['platform', 'capturedAt'] })
    handleError(error)
  },
  async snapshots(platform: string): Promise<SocialSnapshot[]> {
    const { data, error } = await supabase
      .from('social_snapshots')
      .select('*')
      .eq('platform', platform)
      .order('captured_at')
    handleError(error)
    return data ? data.map((r) => SocialSnapshotSchema.parse(r)) : []
  },
  async latest(): Promise<SocialSnapshot[]> {
    // This is complex; we'll do a simpler version for now
    const { data, error } = await supabase
      .from('social_snapshots')
      .select('*')
    handleError(error)
    if (!data) return []

    // Group by platform and get the latest for each
    const latestByPlatform: Record<string, SocialSnapshot> = {}
    data.forEach((snapshot) => {
      const existing = latestByPlatform[snapshot.platform]
      if (!existing || snapshot.capturedAt > existing.capturedAt) {
        latestByPlatform[snapshot.platform] = snapshot
      }
    })

    return Object.values(latestByPlatform).map((s) => SocialSnapshotSchema.parse(s))
  },
  async upsertDm(d: SocialDm): Promise<void> {
    const { error } = await supabase
      .from('social_dms')
      .upsert({ ...d, platform: d.platform }, { onConflict: ['platform'] })
    handleError(error)
  },
  async dms(): Promise<SocialDm[]> {
    const { data, error } = await supabase
      .from('social_dms')
      .select('*')
      .order('updated_at', { ascending: false })
    handleError(error)
    return data ? data.map((r) => SocialDmSchema.parse(r)) : []
  },
  async insertDmSnapshot(s: SocialDmSnapshot): Promise<void> {
    const { error } = await supabase
      .from('social_dm_snapshots')
      .insert({ ...s, id: `${s.platform}-${s.capturedAt}` }, { onConflict: ['platform', 'capturedAt'] })
    handleError(error)
  },
  async dmSnapshots(platform?: string): Promise<SocialDmSnapshot[]> {
    let query = supabase.from('social_dm_snapshots').select('*')
    if (platform) {
      query = query.eq('platform', platform)
    }
    query = query.order('platform, captured_at')
    const { data, error } = await query
    handleError(error)
    return data ? data.map((r) => SocialDmSnapshotSchema.parse(r)) : []
  },
  async upsertDmMessage(m: SocialDmMessage): Promise<void> {
    const { error } = await supabase
      .from('social_dm_messages')
      .upsert({ ...m, id: m.id }, { onConflict: ['id'] })
    handleError(error)
  },
  async dmMessages(platform?: string): Promise<SocialDmMessage[]> {
    let query = supabase.from('social_dm_messages').select('*')
    if (platform) {
      query = query.eq('platform', platform)
    }
    query = query.order('ts', { ascending: false })
    const { data, error } = await query
    handleError(error)
    return data ? data.map((r) => SocialDmMessageSchema.parse(r)) : []
  },
}

// Email List
export const emailList = {
  async insertSnapshot(s: EmailListSnapshot): Promise<void> {
    const { error } = await supabase
      .from('email_list_snapshots')
      .insert({ ...s, id: s.capturedAt }, { onConflict: ['captured_at'] })
    handleError(error)
  },
  async deleteSeeded(): Promise<void> {
    // We'll delete where source like 'seed%' - but note: we are not seeding anymore
    const { error } = await supabase
      .from('email_list_snapshots')
      .delete()
      .like('source', 'seed%')
    handleError(error)
  },
  async snapshots(): Promise<EmailListSnapshot[]> {
    const { data, error } = await supabase
      .from('email_list_snapshots')
      .select('*')
      .order('captured_at')
    handleError(error)
    return data ? data.map((r) => EmailListSnapshotSchema.parse(r)) : []
  },
  async latest(): Promise<EmailListSnapshot | null> {
    const { data, error } = await supabase
      .from('email_list_snapshots')
      .select('*')
      .order('captured_at', { ascending: false })
      .limit(1)
    handleError(error)
    return data && data.length > 0 ? EmailListSnapshotSchema.parse(data[0]) : null
  },
}

// Social Posts
export const socialPosts = {
  async enqueue(p: SocialPost): Promise<void> {
    const { error } = await supabase
      .from('social_posts')
      .insert({ ...p, id: p.id || generateId(), platforms: JSON.stringify(p.platforms) })
    handleError(error)
  },
  async all(): Promise<SocialPost[]> {
    const { data, error } = await supabase
      .from('social_posts')
      .select('*')
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((r) => {
      const parsed = { ...r, platforms: JSON.parse(r.platforms) }
      return SocialPostSchema.parse(parsed)
    }) : []
  },
  async queued(): Promise<SocialPost[]> {
    const { data, error } = await supabase
      .from('social_posts')
      .select('*')
      .eq('status', 'queued')
      .order('created_at', { ascending: false })
    handleError(error)
    return data ? data.map((r) => {
      const parsed = { ...r, platforms: JSON.parse(r.platforms) }
      return SocialPostSchema.parse(parsed)
    }) : []
  },
}

// People
export const people = {
  async all(): Promise<Person[]> {
    const { data, error } = await supabase
      .from('people')
      .select('*')
      .order('department_id, name')
    handleError(error)
    return data ? data.map((r) => PersonSchema.parse({ ...r, tools: JSON.parse(r.tools) })) : []
  },
  async insert(p: Person): Promise<void> {
    const { error } = await supabase
      .from('people')
      .insert({ ...p, id: p.id || generateId(), tools: JSON.stringify(p.tools) })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('people')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Lead Magnets
export const leadMagnets = {
  async all(): Promise<LeadMagnet[]> {
    const { data, error } = await supabase
      .from('lead_magnets')
      .select('*')
      .order('launched_at', { ascending: false })
      .order('name')
    handleError(error)
    return data ? data.map((r) => LeadMagnetSchema.parse({
      ...r,
      origin: r.origin ?? 'seed',
    })) : []
  },
  async insert(m: LeadMagnet): Promise<void> {
    const { error } = await supabase
      .from('lead_magnets')
      .insert({ ...m, id: m.id || generateId(), origin: m.origin ?? 'seed' })
    handleError(error)
  },
  async byId(id: string): Promise<LeadMagnet | null> {
    const { data, error } = await supabase
      .from('lead_magnets')
      .select('*')
      .eq('id', id)
      .single()
    handleError(error)
    if (!data) return null
    return LeadMagnetSchema.parse({
      ...data,
      origin: data.origin ?? 'seed',
    })
  },
  async remove(id: string): Promise<boolean> {
    const { error } = await supabase
      .from('lead_magnets')
      .delete()
      .eq('id', id)
    handleError(error)
    // Note: We don't have changes count from Supabase easily, so we assume it worked if no error
    return true
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('lead_magnets')
      .delete()
      .eq('origin', 'seed')
      .not('id', 'in', ids)
    handleError(error)
  },
}

// SOP Tasks
export const sopTasks = {
  async all(): Promise<SopTask[]> {
    const { data, error } = await supabase
      .from('sop_tasks')
      .select('*')
      .order('department_id, title')
    handleError(error)
    return data ? data.map((r) => SopTaskSchema.parse({ ...r, steps: JSON.parse(r.steps) })) : []
  },
  async insert(t: SopTask): Promise<void> {
    const { error } = await supabase
      .from('sop_tasks')
      .insert({ ...t, id: t.id || generateId(), steps: JSON.stringify(t.steps) })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('sop_tasks')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Workflows
export const workflows = {
  async all(): Promise<Workflow[]> {
    const { data, error } = await supabase
      .from('workflows')
      .select('*')
      .order('ord, name')
    handleError(error)
    return data ? data.map((r) => WorkflowSchema.parse({ ...r, steps: JSON.parse(r.steps) })) : []
  },
  async insert(w: Workflow): Promise<void> {
    const { error } = await supabase
      .from('workflows')
      .insert({ ...w, id: w.id || generateId(), steps: JSON.stringify(w.steps) })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('workflows')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Skills
export const skills = {
  async all(): Promise<Skill[]> {
    const { data, error } = await supabase
      .from('skills')
      .select('*')
      .order('ord, name')
    handleError(error)
    return data ? data.map((r) => SkillSchema.parse({ ...r, tools: JSON.parse(r.tools) })) : []
  },
  async insert(s: Skill): Promise<void> {
    const { error } = await supabase
      .from('skills')
      .insert({ ...s, id: s.id || generateId(), tools: JSON.stringify(s.tools) })
    handleError(error)
  },
  async deleteWhereIdNotIn(ids: string[]): Promise<void> {
    if (ids.length === 0) return
    const { error } = await supabase
      .from('skills')
      .delete()
      .not('id', 'in', ids)
    handleError(error)
  },
}

// Funnel
export const funnel = {
  async insertContact(c: FunnelContact): Promise<void> {
    const { error } = await supabase
      .from('funnel_contacts')
      .insert({ ...c, id: c.id || generateId() })
    handleError(error)
  },
  async insertTouch(t: FunnelTouch): Promise<void> {
    const { error } = await supabase
      .from('funnel_touches')
      .insert({ ...t, id: t.id || generateId() })
    handleError(error)
  },
  async journeys(venture?: string): Promise<FunnelJourney[]> {
    let query = supabase.from('funnel_contacts').select('*')
    if (venture) {
      query = query.eq('venture', venture)
    }
    query = query.order('created_at', { ascending: false })
    const { data: contactData, error: contactError } = await query
    handleError(contactError)
    if (!contactData) return []

    // For each contact, fetch touches
    const journeys = await Promise.all(
      contactData.map(async (contact) => {
        const { data: touchData, error: touchError } = await supabase
          .from('funnel_touches')
          .select('*')
          .eq('contact_id', contact.id)
          .order('seq')
        handleError(touchError)
        return {
          ...contact,
          touches: touchData ? touchData.map((t) => FunnelTouchSchema.parse(t)) : [],
        }
      })
    )

    return journeys.map((j) => FunnelJourneySchema.parse(j))
  },
}

// We'll create a db object that combines all repositories
export const db = {
  departments,
  agents,
  tools,
  roadmap,
  metrics,
  domains,
  personas,
  phases,
  agentRuns,
  agentMessages,
  broadcasts,
  contactTags,
  social,
  emailList,
  socialPosts,
  people,
  leadMagnets,
  sopTasks,
  workflows,
  skills,
  funnel,
}

// We don't have a close method for Supabase, but we can add a placeholder
export const close = () => {
  // No-op
}

// We'll also export a function to get the db (for compatibility with the old getDb)
// But note: our db is already an object, so we can just return it.
export function getDb() {
  return db
}