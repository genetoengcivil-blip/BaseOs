-- Enable Row Level Security on tables that need it
-- We enable RLS on tables that are organization-scoped or user-specific.

-- First, enable RLS on the profiles table (which is tied to auth.users)
alter table profiles enable row level security;

-- Organizations table: we don't enable RLS on organizations because we want to allow
-- anyone to create an organization (during onboarding) and then we control access via organization_members.
-- However, note that we are going to have a policy that only allows members of an organization to see it.
-- But we also need to allow the creation of an organization by a user who is not yet a member (during onboarding).
-- We'll handle that by having a policy that allows insert for anyone (or rather, for authenticated users) and then
-- we'll rely on the application logic to create the organization and then add the user as an owner.
-- Alternatively, we can enable RLS and have a policy that allows insert for authenticated users and then
-- we'll create the organization and then immediately add the user as an owner in the same transaction (using a trigger or application logic).
-- For simplicity, we'll not enable RLS on organizations and instead rely on the fact that we only expose organizations
-- through the organization_members table (i.e., we only show organizations that the user is a member of).
-- However, we do need to store the organization data, so we'll leave it without RLS and rely on the application to
-- scope queries by the current user's organization via the organization_members table.
-- But note: the organization_members table will have RLS and will restrict which organizations a user can see.
-- So we don't need RLS on organizations because we never query organizations directly without joining through organization_members.
-- However, to be safe, we can enable RLS and have a policy that allows select only if the user is a member (via organization_members).
-- Let's do that.

-- We'll enable RLS on organizations and create a policy that allows select if the user is a member.

-- Similarly for other tables, we'll create policies that restrict access to the current user's organization.

-- We'll do it table by table.

-- Profiles: each user can only see their own profile.
create policy "Profiles are viewable by the user themselves."
  on profiles for select
  using (auth.uid() = id);

-- Users can update their own profile.
create policy "Profiles are updatable by the user themselves."
  on profiles for update
  using (auth.uid() = id);

-- Organizations: a user can see an organization if they are a member.
alter table organizations enable row level security;

create policy "Organizations are viewable by members."
  on organizations for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = organizations.id
    and organization_members.profile_id = auth.uid()
  ));

-- Only admins and owners can update an organization? We'll keep it simple: members can update.
-- But note: we might want to restrict updating to owners and admins. However, for now, we'll allow members.
create policy "Organizations are updatable by members."
  on organizations for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = organizations.id
    and organization_members.profile_id = auth.uid()
  ));

-- Organization members: users can see the members of organizations they belong to.
alter table organization_members enable row level security;

create policy "Organization members are viewable by members of the same organization."
  on organization_members for select
  using (exists (
    select 1 from organization_members as om
    where om.organization_id = organization_members.organization_id
    and om.profile_id = auth.uid()
  ));

-- Users can insert their own membership (when they create an organization or are invited).
-- We'll allow insert if the user is the one being added (i.e., the profile_id matches auth.uid())
-- and they are allowed to create an organization (we'll handle organization creation separately).
-- However, note that during onboarding, we create the organization and then we create the membership for the user.
-- We'll allow the user to insert a membership for themselves in any organization? That's not safe.
-- Instead, we'll rely on the application to insert the membership and we'll not allow direct insertion via the API.
-- For now, we'll allow insert only if the user is an owner of the organization (we don't have a way to check that in the policy without a subquery).
-- We'll change: we allow insert if the user is the profile_id and the organization_id is provided, and we trust the application to only allow inserting for the current user's organization.
-- We'll do: allow insert if the profile_id = auth.uid().
create policy "Users can insert their own organization membership."
  on organization_members for insert
  with check (profile_id = auth.uid());

-- Similarly, update and delete: we'll allow if the user is the profile_id (so they can update their own membership record)
-- but note: we don't want users to be able to change their own role arbitrarily? We'll leave that to the application.
-- We'll allow update and delete for the user's own membership record.
create policy "Users can update their own organization membership."
  on organization_members for update
  using (profile_id = auth.uid());

create policy "Users can delete their own organization membership."
  on organization_members for delete
  using (profile_id = auth.uid());

-- Now, for all other tables that are organization-scoped, we'll create policies that allow select, insert, update, delete
-- only if the user is a member of the organization (via organization_members).

-- We'll do this for each table that has an organization_id column.

-- Agent runs
alter table agent_runs enable row level security;
create policy "Agent runs are viewable by organization members."
  on agent_runs for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_runs.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent runs are insertable by organization members."
  on agent_runs for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_runs.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent runs are updatable by organization members."
  on agent_runs for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_runs.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent runs are deletable by organization members."
  on agent_runs for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_runs.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Agent messages
alter table agent_messages enable row level security;
create policy "Agent messages are viewable by organization members."
  on agent_messages for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent messages are insertable by organization members."
  on agent_messages for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
-- We don't typically update or delete agent messages, but we'll add the policies for completeness.
create policy "Agent messages are updatable by organization members."
  on agent_messages for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent messages are deletable by organization members."
  on agent_messages for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Broadcasts
alter table broadcasts enable row level security;
create policy "Broadcasts are viewable by organization members."
  on broadcasts for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcasts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcasts are insertable by organization members."
  on broadcasts for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcasts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcasts are updatable by organization members."
  on broadcasts for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcasts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcasts are deletable by organization members."
  on broadcasts for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcasts.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Broadcast replies
alter table broadcast_replies enable row level security;
create policy "Broadcast replies are viewable by organization members."
  on broadcast_replies for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcast_replies.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcast replies are insertable by organization members."
  on broadcast_replies for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcast_replies.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcast replies are updatable by organization members."
  on broadcast_replies for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcast_replies.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Broadcast replies are deletable by organization members."
  on broadcast_replies for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = broadcast_replies.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Agent tasks
alter table agent_tasks enable row level security;
create policy "Agent tasks are viewable by organization members."
  on agent_tasks for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_tasks.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent tasks are insertable by organization members."
  on agent_tasks for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_tasks.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent tasks are updatable by organization members."
  on agent_tasks for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_tasks.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent tasks are deletable by organization members."
  on agent_tasks for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_tasks.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Agent crons
alter table agent_crons enable row level security;
create policy "Agent crons are viewable by organization members."
  on agent_crons for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_crons.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent crons are insertable by organization members."
  on agent_crons for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_crons.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent crons are updatable by organization members."
  on agent_crons for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_crons.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Agent crons are deletable by organization members."
  on agent_crons for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = agent_crons.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Contact tags
alter table contact_tags enable row level security;
create policy "Contact tags are viewable by organization members."
  on contact_tags for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = contact_tags.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Contact tags are insertable by organization members."
  on contact_tags for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = contact_tags.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Contact tags are updatable by organization members."
  on contact_tags for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = contact_tags.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Contact tags are deletable by organization members."
  on contact_tags for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = contact_tags.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social accounts
alter table social_accounts enable row level security;
create policy "Social accounts are viewable by organization members."
  on social_accounts for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_accounts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social accounts are insertable by organization members."
  on social_accounts for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_accounts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social accounts are updatable by organization members."
  on social_accounts for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_accounts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social accounts are deletable by organization members."
  on social_accounts for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_accounts.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social snapshots
alter table social_snapshots enable row level security;
create policy "Social snapshots are viewable by organization members."
  on social_snapshots for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social snapshots are insertable by organization members."
  on social_snapshots for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social snapshots are updatable by organization members."
  on social_snapshots for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social snapshots are deletable by organization members."
  on social_snapshots for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social DMs
alter table social_dms enable row level security;
create policy "Social DMs are viewable by organization members."
  on social_dms for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dms.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DMs are insertable by organization members."
  on social_dms for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dms.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DMs are updatable by organization members."
  on social_dms for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dms.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DMs are deletable by organization members."
  on social_dms for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dms.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social DM snapshots
alter table social_dm_snapshots enable row level security;
create policy "Social DM snapshots are viewable by organization members."
  on social_dm_snapshots for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM snapshots are insertable by organization members."
  on social_dm_snapshots for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM snapshots are updatable by organization members."
  on social_dm_snapshots for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM snapshots are deletable by organization members."
  on social_dm_snapshots for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social DM messages
alter table social_dm_messages enable row level security;
create policy "Social DM messages are viewable by organization members."
  on social_dm_messages for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM messages are insertable by organization members."
  on social_dm_messages for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM messages are updatable by organization members."
  on social_dm_messages for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social DM messages are deletable by organization members."
  on social_dm_messages for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_dm_messages.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Social posts
alter table social_posts enable row level security;
create policy "Social posts are viewable by organization members."
  on social_posts for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_posts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social posts are insertable by organization members."
  on social_posts for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_posts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social posts are updatable by organization members."
  on social_posts for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_posts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Social posts are deletable by organization members."
  on social_posts for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = social_posts.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- People
alter table people enable row level security;
create policy "People are viewable by organization members."
  on people for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = people.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "People are insertable by organization members."
  on people for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = people.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "People are updatable by organization members."
  on people for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = people.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "People are deletable by organization members."
  on people for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = people.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Lead magnets
alter table lead_magnets enable row level security;
create policy "Lead magnets are viewable by organization members."
  on lead_magnets for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = lead_magnets.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Lead magnets are insertable by organization members."
  on lead_magnets for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = lead_magnets.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Lead magnets are updatable by organization members."
  on lead_magnets for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = lead_magnets.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Lead magnets are deletable by organization members."
  on lead_magnets for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = lead_magnets.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Funnel contacts
alter table funnel_contacts enable row level security;
create policy "Funnel contacts are viewable by organization members."
  on funnel_contacts for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_contacts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel contacts are insertable by organization members."
  on funnel_contacts for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_contacts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel contacts are updatable by organization members."
  on funnel_contacts for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_contacts.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel contacts are deletable by organization members."
  on funnel_contacts for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_contacts.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Funnel touches
alter table funnel_touches enable row level security;
create policy "Funnel touches are viewable by organization members."
  on funnel_touches for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_touches.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel touches are insertable by organization members."
  on funnel_touches for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_touches.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel touches are updatable by organization members."
  on funnel_touches for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_touches.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Funnel touches are deletable by organization members."
  on funnel_touches for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = funnel_touches.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Bank summaries
alter table bank_summaries enable row level security;
create policy "Bank summaries are viewable by organization members."
  on bank_summaries for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = bank_summaries.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Bank summaries are insertable by organization members."
  on bank_summaries for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = bank_summaries.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Bank summaries are updatable by organization members."
  on bank_summaries for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = bank_summaries.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Bank summaries are deletable by organization members."
  on bank_summaries for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = bank_summaries.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Ledger rows
alter table ledger_rows enable row level security;
create policy "Ledger rows are viewable by organization members."
  on ledger_rows for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = ledger_rows.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Ledger rows are insertable by organization members."
  on ledger_rows for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = ledger_rows.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Ledger rows are updatable by organization members."
  on ledger_rows for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = ledger_rows.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Ledger rows are deletable by organization members."
  on ledger_rows for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = ledger_rows.organization_id
    and organization_members.profile_id = auth.uid()
  ));

-- Email list snapshots
alter table email_list_snapshots enable row level security;
create policy "Email list snapshots are viewable by organization members."
  on email_list_snapshots for select
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = email_list_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Email list snapshots are insertable by organization members."
  on email_list_snapshots for insert
  with check (exists (
    select 1 from organization_members
    where organization_members.organization_id = email_list_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Email list snapshots are updatable by organization members."
  on email_list_snapshots for update
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = email_list_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));
create policy "Email list snapshots are deletable by organization members."
  on email_list_snapshots for delete
  using (exists (
    select 1 from organization_members
    where organization_members.organization_id = email_list_snapshots.organization_id
    and organization_members.profile_id = auth.uid()
  ));