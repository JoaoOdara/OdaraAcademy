-- ═══════════════════════════════════════════════════════════
-- ODARA ACADEMY — MIGRAÇÃO V3
-- Curadoria externa de conteúdos gratuitos
-- ═══════════════════════════════════════════════════════════

-- 1. Tabela de itens de curadoria
create table if not exists curadoria_externa (
  id              uuid primary key default gen_random_uuid(),
  titulo          text not null,
  descricao       text,
  url             text not null,
  fonte           text,                            -- ex: SENAI, SEBRAE, YouTube/Canal
  area            text not null,                   -- Qualidade, Produção, Liderança, Segurança, Manutenção, Geral
  formato         text not null check (formato in ('video','curso','artigo','podcast','ebook','planilha')),
  duracao_min     integer,                         -- duração estimada
  nivel           text default 'todos' check (nivel in ('iniciante','intermediario','avancado','todos')),
  thumb_url       text,                            -- imagem de capa opcional
  destaque        boolean default false,           -- aparece no topo da área
  ativo           boolean default true,
  criado_por      uuid references profiles(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists curadoria_area_idx on curadoria_externa(area);
create index if not exists curadoria_ativo_idx on curadoria_externa(ativo);

-- 2. Registro de acessos (opcional, para métricas futuras)
create table if not exists curadoria_acessos (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references profiles(id) on delete cascade,
  curadoria_id uuid not null references curadoria_externa(id) on delete cascade,
  acessado_em  timestamptz not null default now()
);

create index if not exists curadoria_acessos_profile_idx on curadoria_acessos(profile_id);

-- 3. RLS — todos veem, só admin/gestor edita
alter table curadoria_externa enable row level security;
alter table curadoria_acessos enable row level security;

drop policy if exists "curadoria_select_all" on curadoria_externa;
create policy "curadoria_select_all" on curadoria_externa
  for select using (auth.role() = 'authenticated' and ativo = true);

drop policy if exists "curadoria_insert_admin" on curadoria_externa;
create policy "curadoria_insert_admin" on curadoria_externa
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role in ('admin','gestor'))
  );

drop policy if exists "curadoria_update_admin" on curadoria_externa;
create policy "curadoria_update_admin" on curadoria_externa
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role in ('admin','gestor'))
  );

drop policy if exists "curadoria_delete_admin" on curadoria_externa;
create policy "curadoria_delete_admin" on curadoria_externa
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "acessos_select_self" on curadoria_acessos;
create policy "acessos_select_self" on curadoria_acessos
  for select using (profile_id = auth.uid() or
    exists (select 1 from profiles where id = auth.uid() and role in ('admin','gestor')));

drop policy if exists "acessos_insert_self" on curadoria_acessos;
create policy "acessos_insert_self" on curadoria_acessos
  for insert with check (profile_id = auth.uid());

-- 4. SEEDS — Curadoria inicial pertinente à indústria de alimentos
insert into curadoria_externa (titulo, descricao, url, fonte, area, formato, duracao_min, nivel, destaque) values

-- QUALIDADE
('Boas Práticas de Fabricação na Indústria de Alimentos', 'Curso gratuito do SENAI sobre BPF aplicada à produção de alimentos.', 'https://www.escolavirtual.gov.br/curso/364', 'Escola Virtual.gov', 'Qualidade', 'curso', 480, 'iniciante', true),
('APPCC Análise de Perigos e Pontos Críticos de Controle', 'Curso introdutório do SENAI sobre o sistema APPCC.', 'https://www.youtube.com/results?search_query=appcc+industria+alimentos', 'YouTube', 'Qualidade', 'video', 60, 'intermediario', true),
('Higiene na Manipulação de Alimentos — ANVISA', 'Cartilha oficial da ANVISA sobre boas práticas de manipulação.', 'https://www.gov.br/anvisa/pt-br/centraisdeconteudo/publicacoes/alimentos/cartilha-boas-praticas-para-servicos-de-alimentacao.pdf', 'ANVISA', 'Qualidade', 'ebook', 30, 'iniciante', false),
('Codex Alimentarius — Princípios Gerais de Higiene', 'Documento base internacional para higiene em alimentos.', 'https://www.fao.org/fao-who-codexalimentarius/codex-texts/codes-of-practice/pt/', 'FAO/WHO', 'Qualidade', 'ebook', 90, 'avancado', false),

-- PRODUÇÃO
('Lean Manufacturing na Indústria de Alimentos', 'Vídeo sobre aplicação de Lean em linhas produtivas.', 'https://www.youtube.com/results?search_query=lean+manufacturing+alimentos', 'YouTube', 'Produção', 'video', 45, 'intermediario', true),
('5S no Chão de Fábrica', 'Curso prático de 5S aplicado à indústria.', 'https://www.escolavirtual.gov.br/curso/210', 'Escola Virtual.gov', 'Produção', 'curso', 240, 'iniciante', true),
('PCP — Planejamento e Controle da Produção', 'Fundamentos de PCP para indústria.', 'https://www.youtube.com/results?search_query=pcp+industria+alimentos', 'YouTube', 'Produção', 'video', 60, 'intermediario', false),
('OEE — Eficiência Global de Equipamentos', 'Como calcular e melhorar o OEE.', 'https://www.youtube.com/results?search_query=oee+industria', 'YouTube', 'Produção', 'video', 30, 'intermediario', false),

-- LIDERANÇA
('Liderança no Chão de Fábrica', 'Curso SEBRAE sobre liderança de equipes operacionais.', 'https://sebrae.com.br/sites/PortalSebrae/cursosonline', 'SEBRAE', 'Liderança', 'curso', 360, 'iniciante', true),
('Comunicação Não Violenta para Líderes', 'Como dar feedback sem desgaste.', 'https://www.youtube.com/results?search_query=cnv+lideran%C3%A7a', 'YouTube', 'Liderança', 'video', 45, 'todos', true),
('Reuniões eficazes em 15 minutos', 'Estrutura de DDS e reuniões rápidas de turno.', 'https://www.youtube.com/results?search_query=dds+di%C3%A1logo+seguran%C3%A7a', 'YouTube', 'Liderança', 'video', 20, 'iniciante', false),
('Como dar feedback ao operador', 'Modelo SCI de feedback aplicado à indústria.', 'https://www.youtube.com/results?search_query=feedback+lideran%C3%A7a+ind%C3%BAstria', 'YouTube', 'Liderança', 'video', 25, 'intermediario', false),

-- SEGURANÇA
('NR-12 Segurança em Máquinas — básico', 'Curso gratuito sobre proteção de máquinas.', 'https://www.escolavirtual.gov.br/curso/231', 'Escola Virtual.gov', 'Segurança', 'curso', 180, 'iniciante', true),
('NR-35 Trabalho em Altura', 'Capacitação básica em trabalho em altura.', 'https://www.youtube.com/results?search_query=nr-35+trabalho+em+altura', 'YouTube', 'Segurança', 'video', 40, 'iniciante', false),
('CIPA — Comissão Interna de Prevenção de Acidentes', 'O que faz e como atuar.', 'https://www.youtube.com/results?search_query=cipa+industria', 'YouTube', 'Segurança', 'video', 30, 'todos', false),
('Ergonomia na linha de produção', 'Princípios de ergonomia aplicados à manufatura.', 'https://www.youtube.com/results?search_query=ergonomia+linha+produ%C3%A7%C3%A3o', 'YouTube', 'Segurança', 'video', 35, 'iniciante', false),

-- MANUTENÇÃO
('Manutenção Autônoma — TPM', 'Conceitos de TPM e manutenção autônoma para operadores.', 'https://www.youtube.com/results?search_query=tpm+manuten%C3%A7%C3%A3o+aut%C3%B4noma', 'YouTube', 'Manutenção', 'video', 50, 'intermediario', true),
('Lubrificação Industrial básica', 'Tipos de lubrificantes e periodicidade.', 'https://www.youtube.com/results?search_query=lubrifica%C3%A7%C3%A3o+industrial', 'YouTube', 'Manutenção', 'video', 30, 'iniciante', false),
('Setup rápido SMED', 'Redução de tempo de troca de produto na linha.', 'https://www.youtube.com/results?search_query=smed+setup+r%C3%A1pido', 'YouTube', 'Manutenção', 'video', 40, 'intermediario', false),

-- GERAL
('Excel para a indústria — fórmulas essenciais', 'Curso prático focado em rotina de fábrica.', 'https://www.escolavirtual.gov.br/curso/97', 'Escola Virtual.gov', 'Geral', 'curso', 240, 'iniciante', true),
('Indústria 4.0 — visão geral', 'Introdução acessível aos conceitos de Indústria 4.0.', 'https://www.youtube.com/results?search_query=ind%C3%BAstria+4.0+alimentos', 'YouTube', 'Geral', 'video', 35, 'todos', false),
('Sustentabilidade na Indústria de Alimentos', 'Como reduzir desperdício e impacto.', 'https://www.youtube.com/results?search_query=sustentabilidade+ind%C3%BAstria+alimentos', 'YouTube', 'Geral', 'video', 40, 'todos', false)

on conflict do nothing;

-- ═══════════════════════════════════════════════════════════
-- FIM
-- ═══════════════════════════════════════════════════════════
