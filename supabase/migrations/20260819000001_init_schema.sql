-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (extends auth.users)
create table profiles (
  id uuid references auth.users not null primary key,
  name text,
  role text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Organizations table
create table organizations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  slug text not null unique,
  tagline text,
  website text,
  size text,
  country text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Organization members table (links profiles to organizations)
create table organization_members (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id, organization_id)
);

-- Global tables (not tied to an organization)

-- Departments
create table departments (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  slug text not null unique,
  tagline text not null default '',
  color text not null,
  "order" integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Agents
create table agents (
  id uuid primary key default uuid_generate_v4(),
  department_id uuid not null references departments(id) on delete cascade,
  name text not null,
  role text not null default '',
  status text not null,
  tier text not null,
  description text not null,
  model text,
  tools text[], -- Array of strings
  parent_id uuid references agents(id) on delete set null,
  instance text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tools
create table tools (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Roadmap items
create table roadmap_items (
  id uuid primary key default uuid_generate_v4(),
  quarter text not null,
  title text not null,
  description text,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Metrics
create table metrics (
  id uuid primary key default uuid_generate_v4(),
  label text not null,
  value text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Domains
create table domains (
  id uuid primary key default uuid_generate_v4(),
  number integer not null,
  title text not null,
  description text,
  items jsonb not null, -- Changed from text to jsonb for better querying
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Personas
create table personas (
  id uuid primary key default uuid_generate_v4(),
  ord integer not null,
  name text not null,
  pillars jsonb not null,
  connectors jsonb not null,
  metrics jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Phases
create table phases (
  id uuid primary key default uuid_generate_v4(),
  number integer not null,
  title text not null,
  description text,
  items jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- SOP tasks
create table sop_tasks (
  id uuid primary key default uuid_generate_v4(),
  department_id uuid not null references departments(id) on delete cascade,
  title text not null,
  steps jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Workflows
create table workflows (
  id uuid primary key default uuid_generate_v4(),
  ord integer not null,
  name text not null,
  steps jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Skills
create table skills (
  id uuid primary key default uuid_generate_v4(),
  ord integer not null,
  name text not null,
  tools jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Organization-scoped tables

-- Agent runs
create table agent_runs (
  id uuid primary key default uuid_generate_v4(),
  agent_id uuid not null references agents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz,
  status text not null,
  result text,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Agent messages
create table agent_messages (
  id uuid primary key default uuid_generate_v4(),
  agent_id uuid not null references agents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  tool_calls jsonb not null, -- Changed from text to jsonb
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Broadcasts
create table broadcasts (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Broadcast replies
create table broadcast_replies (
  id uuid primary key default uuid_generate_v4(),
  broadcast_id uuid not null references broadcasts(id) on delete cascade,
  agent_id uuid not null references agents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Agent tasks
create table agent_tasks (
  id uuid primary key default uuid_generate_v4(),
  agent_id uuid not null references agents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Agent crons
create table agent_crons (
  id uuid primary key default uuid_generate_v4(),
  agent_id uuid not null references agents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  cron text not null,
  enabled integer not null default 1, -- 1 for true, 0 for false
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Contact tags
create table contact_tags (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  person text not null,
  channel text not null,
  tier integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, person, channel)
);

-- Social accounts
create table social_accounts (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platform text not null,
  username text,
  "order" integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, platform)
);

-- Social snapshots
create table social_snapshots (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platform text not null,
  captured_at timestamptz not null,
  followers integer,
  following integer,
  posts integer,
  engagement_rate numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, platform, captured_at)
);

-- Social DMs
create table social_dms (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platform text not null,
  username text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, platform)
);

-- Social DM snapshots
create table social_dm_snapshots (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platform text not null,
  captured_at timestamptz not null,
  count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, platform, captured_at)
);

-- Social DM messages
create table social_dm_messages (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platform text not null,
  direction text not null, -- 'in' or 'out'
  timestamp timestamptz not null,
  message text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Social posts
create table social_posts (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  platforms text[] not null, -- Array of strings
  schedule timestamptz not null,
  status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- People
create table people (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  department_id uuid not null references departments(id) on delete cascade,
  name text not null,
  tools jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lead magnets
create table lead_magnets (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  origin text not null default 'seed',
  launched_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Funnel contacts
create table funnel_contacts (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  venture text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Funnel touches
create table funnel_touches (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  contact_id uuid not null references funnel_contacts(id) on delete cascade,
  seq integer not null,
  type text not null,
  timestamp timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Funnel journeys (we'll create a view or just use the contacts and touches; but we can have a table for denormalized journey if needed)
-- We'll skip the funnel_journeys table for now and compute it from contacts and touches.

-- Bank summaries (for bank integration)
create table bank_summaries (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  account text not null,
  business text not null,
  month text not null,
  credits_cents integer not null,
  debits_cents integer not null,
  net_cents integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, account, month)
);

-- Ledger rows (for ledger integration)
create table ledger_rows (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  hash text not null unique,
  date text not null,
  description text not null,
  amount_cents integer not null,
  direction text not null check (direction in ('in', 'out')),
  category text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Email list snapshots
create table email_list_snapshots (
  id uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  captured_at date not null,
  source text not null,
  total_subscribers integer not null,
  new_subscribers integer not null,
  unsubscribes integer not null,
  open_rate numeric,
  click_rate numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, captured_at, source)
);

-- Enable Row Level Security
-- We will enable RLS and create policies in a separate migration or in this one.
-- For now, we'll just enable RLS on the tables that need it (organization-scoped tables and profiles, organizations, organization_members).
-- We'll do it in the next migration for clarity.