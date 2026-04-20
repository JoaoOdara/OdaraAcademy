-- ═══════════════════════════════════════════════════════════
-- ODARA ACADEMY — Migração V4
-- Suporte aos painéis de Gestor e Admin
-- Rode no SQL Editor do Supabase APÓS as migrações anteriores
-- ═══════════════════════════════════════════════════════════

-- ── 1. Expectativa de nível por CARGO (usada em "Matriz por cargo" no admin)
create table if not exists expectativa_cargo (
  id             uuid primary key default gen_random_uuid(),
  cargo_id       uuid not null references cargos(id) on delete cascade,
  competencia_id uuid not null references competencias(id) on delete cascade,
  nivel_desejado smallint not null check (nivel_desejado between 0 and 4),
  created_at     timestamptz not null default now(),
  unique (cargo_id, competencia_id)
);

alter table expectativa_cargo enable row level security;

drop policy if exists ec_all on expectativa_cargo;
create policy ec_all on expectativa_cargo for all to authenticated using (true) with check (true);


-- ── 2. Garante colunas mínimas em profiles (se ainda faltarem)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='ativo') then
    alter table profiles add column ativo boolean not null default true;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='email') then
    alter table profiles add column email text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='cargo') then
    alter table profiles add column cargo text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='area') then
    alter table profiles add column area text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='turno') then
    alter table profiles add column turno text;
  end if;
end $$;


-- ── 3. Trilhas_atribuicoes: garante tabela e RLS
create table if not exists trilhas_atribuicoes (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references profiles(id) on delete cascade,
  trilha_id       uuid not null references trilhas(id) on delete cascade,
  atribuido_por   uuid references profiles(id),
  atribuido_em    timestamptz not null default now(),
  unique (profile_id, trilha_id)
);

alter table trilhas_atribuicoes enable row level security;
drop policy if exists ta_all on trilhas_atribuicoes;
create policy ta_all on trilhas_atribuicoes for all to authenticated using (true) with check (true);


-- ── 4. Progressoes_competencia: garante campos usados pelo painel de gestor
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name='progressoes_competencia' and column_name='supervisor_status') then
    alter table progressoes_competencia add column supervisor_status text default 'pendente';
    alter table progressoes_competencia add column supervisor_obs text;
    alter table progressoes_competencia add column supervisor_em timestamptz;
    alter table progressoes_competencia add column supervisor_id uuid references profiles(id);
  end if;
  if not exists (select 1 from information_schema.columns where table_name='progressoes_competencia' and column_name='facilitador_status') then
    alter table progressoes_competencia add column facilitador_status text default 'pendente';
    alter table progressoes_competencia add column facilitador_obs text;
    alter table progressoes_competencia add column facilitador_em timestamptz;
    alter table progressoes_competencia add column facilitador_id uuid references profiles(id);
  end if;
end $$;


-- ── 5. Trigger: quando ambas aprovações concluem, atualiza matriz_competencias
create or replace function aplicar_progressao()
returns trigger language plpgsql as $$
begin
  if new.supervisor_status = 'aprovado'
     and (new.facilitador_id is null or new.facilitador_status = 'aprovado') then
    insert into matriz_competencias (profile_id, competencia_id, nivel_atual, updated_at)
    values (new.profile_id, new.competencia_id, new.nivel_solicitado, now())
    on conflict (profile_id, competencia_id)
    do update set nivel_atual = excluded.nivel_atual, updated_at = now();
  end if;
  return new;
end; $$;

drop trigger if exists trg_aplicar_progressao on progressoes_competencia;
create trigger trg_aplicar_progressao
  after update on progressoes_competencia
  for each row execute function aplicar_progressao();


-- ═══════════════════════════════════════════════════════════
-- FIM
-- ═══════════════════════════════════════════════════════════
