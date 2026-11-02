-- Audit log for the JE control monitor (Supabase / Postgres).
-- One row per journal entry per run. The unique key makes the log append-only in practice:
-- rerunning the same month under the same policy version is rejected row by row (first write wins),
-- while a rerun under a new policy version is recorded as new rows.

create table if not exists public.je_control_audit_log (
  id                bigint generated always as identity primary key,
  run_month         text        not null,           -- e.g. '2026-09'
  entry_number      text        not null,
  entity            text,
  currency          text,
  amount            numeric,
  amount_eur        numeric,
  fx_rate           numeric,
  required_approval text,                            -- None | Controller | CFO
  created_by        text,
  approved_by       text,
  approver_role     text,
  source            text,                            -- manual | upload
  description       text,
  result            text        not null,           -- pass | review | exception
  findings          jsonb,
  explanation       jsonb,                           -- Claude's explanation, or null for passing entries
  policy_version    text        not null,
  checked_at        timestamptz,
  eval_label        jsonb,                           -- planted issue in the synthetic data (eval only)
  logged_at         timestamptz not null default now(),
  constraint je_control_audit_log_unique_run unique (run_month, entry_number, policy_version)
);

alter table public.je_control_audit_log enable row level security;
-- n8n writes with the service-role key, which bypasses RLS. Add read policies for any other role that needs access.
