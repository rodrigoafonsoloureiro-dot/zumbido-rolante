-- ===== Zumbido Rolante · base de dados =====
-- Colar tudo no SQL Editor da Supabase e carregar em "Run".

-- 1) Tabela de viaturas
create table if not exists public.carros (
  id uuid primary key default gen_random_uuid(),
  criado bigint not null default (extract(epoch from now())*1000)::bigint,
  marca text not null,
  modelo text not null,
  versao text default '',
  ano int,
  km int default 0,
  comb text default '',
  caixa text default '',
  cv int default 0,
  lug int default 5,
  carr text default '',
  cor text default '',
  hex text default '#8a8d92',
  preco numeric not null,
  destaque text default '',
  eq text[] default '{}',
  descricao text default '',
  fotos text[] default '{}',
  vendido boolean default false
);

-- 2) Lista de administradores (quem pode gerir o stock)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- 3) Regras de segurança
alter table public.carros enable row level security;
alter table public.admins enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.admins where user_id = auth.uid());
$$;

drop policy if exists "carros: todos leem" on public.carros;
create policy "carros: todos leem" on public.carros for select using (true);
drop policy if exists "carros: admin escreve" on public.carros;
create policy "carros: admin escreve" on public.carros for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins: ver o proprio" on public.admins;
create policy "admins: ver o proprio" on public.admins for select to authenticated
  using (user_id = auth.uid());

-- 4) Pasta pública para as fotos
insert into storage.buckets (id, name, public) values ('fotos','fotos', true)
  on conflict (id) do nothing;

drop policy if exists "fotos: todos veem" on storage.objects;
create policy "fotos: todos veem" on storage.objects for select using (bucket_id = 'fotos');
drop policy if exists "fotos: admin carrega" on storage.objects;
create policy "fotos: admin carrega" on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and public.is_admin());
drop policy if exists "fotos: admin altera" on storage.objects;
create policy "fotos: admin altera" on storage.objects for update to authenticated
  using (bucket_id = 'fotos' and public.is_admin());
drop policy if exists "fotos: admin apaga" on storage.objects;
create policy "fotos: admin apaga" on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and public.is_admin());

-- 5) Viaturas de exemplo (só se a tabela estiver vazia)
insert into public.carros (marca,modelo,versao,ano,km,comb,caixa,cv,lug,carr,cor,hex,preco,destaque,eq,descricao,fotos,vendido,criado)
select * from (values
  ('Porsche','Cayenne Electric','Base',2026,3500,'Elétrico','Automática',435,5,'SUV','Cinzento','#4a5058',119900,'Premium',ARRAY['GPS','Câmara 360º','Bancos aquecidos','Teto panorâmico','Faróis LED','Cruise control']::text[],'SUV 100% elétrico com desempenho Porsche, carregamento rápido e interior topo de gama. Praticamente novo.',ARRAY['img/porsche.webp']::text[],false,11),
  ('Mercedes-Benz','GLE 300 d 4MATIC','AMG Line',2024,18500,'Diesel','Automática',269,5,'SUV','Branco','#ececec',84900,'Destaque',ARRAY['GPS','Câmara 360º','Bancos aquecidos','Teto panorâmico','Faróis LED','Cruise control','Apple CarPlay / Android Auto']::text[],'SUV de luxo com tração integral, pack AMG Line, faróis Multibeam LED e ecrã MBUX duplo.',ARRAY['img/mercedes.jpg']::text[],false,10),
  ('BMW','X3 20 xDrive','M Sport',2025,12000,'Gasolina','Automática',208,5,'SUV','Cinzento','#8a8d92',62900,'Novo',ARRAY['GPS','Câmara traseira','Bancos aquecidos','Faróis LED','Cruise control','Apple CarPlay / Android Auto']::text[],'Nova geração do X3 com pack M Sport, tração xDrive e o mais recente sistema iDrive.',ARRAY['img/bmw.webp']::text[],false,9),
  ('Citroën','C5 Aircross 1.5 BlueHDi','Shine',2021,51000,'Diesel','Automática',130,5,'SUV','Branco','#ececec',23900,'',ARRAY['GPS','Câmara traseira','Teto panorâmico','Cruise control']::text[],'Conforto acima da média, com suspensão progressiva e muito espaço.',ARRAY[]::text[],false,8),
  ('Skoda','Octavia Break 2.0 TDI','Style',2020,98000,'Diesel','Automática',150,5,'Carrinha','Cinzento','#7c7f86',21900,'',ARRAY['GPS','Apple CarPlay / Android Auto','Bancos aquecidos','Cruise control','Sensores de estacionamento']::text[],'Carrinha familiar enorme por dentro, ótima para viagens.',ARRAY[]::text[],false,7),
  ('Tesla','Model 3','Standard Range Plus',2021,42000,'Elétrico','Automática',325,5,'Sedan','Vermelho','#b31010',29900,'',ARRAY['GPS','Câmara 360º','Bancos aquecidos','Teto panorâmico','Cruise control']::text[],'100% elétrico, com Autopilot e atualizações remotas.',ARRAY[]::text[],false,6),
  ('Peugeot','308 1.5 BlueHDi','Allure',2021,48000,'Diesel','Manual',130,5,'Hatchback','Cinzento','#c9ccd1',18900,'',ARRAY['GPS','Apple CarPlay / Android Auto','Câmara traseira','Cruise control','Sensores de estacionamento']::text[],'Muito económico e bem equipado. Revisões em dia e pneus novos.',ARRAY[]::text[],false,5),
  ('Toyota','Yaris 1.5 Hybrid','Comfort',2022,19800,'Híbrido','Automática',116,5,'Hatchback','Branco','#f1f1f1',19750,'',ARRAY['Apple CarPlay / Android Auto','Câmara traseira','Cruise control']::text[],'Consumos muito baixos em cidade, caixa automática e Toyota Safety Sense.',ARRAY[]::text[],false,4),
  ('Seat','Arona 1.0 TSI','FR',2020,57000,'Gasolina','Manual',110,5,'SUV','Cinzento','#d4d4d8',16490,'',ARRAY['Apple CarPlay / Android Auto','Câmara traseira','Faróis LED']::text[],'Crossover com visual FR, posição de condução elevada e bom espaço.',ARRAY[]::text[],false,3),
  ('Volkswagen','Golf 2.0 TDI','Life',2019,89000,'Diesel','Manual',115,5,'Hatchback','Azul','#2b5aa8',16900,'',ARRAY['GPS','Cruise control','Sensores de estacionamento']::text[],'Um clássico fiável e espaçoso, com climatização automática.',ARRAY[]::text[],false,2),
  ('Renault','Clio 1.0 TCe','Intens',2022,22500,'Gasolina','Manual',90,5,'Hatchback','Vermelho','#e10600',15490,'',ARRAY['Apple CarPlay / Android Auto','Câmara traseira','Faróis LED','Sensores de estacionamento']::text[],'Citadino ágil, com faróis LED e jantes de liga leve. Ideal como primeiro carro.',ARRAY[]::text[],false,1)
) as v(marca,modelo,versao,ano,km,comb,caixa,cv,lug,carr,cor,hex,preco,destaque,eq,descricao,fotos,vendido,criado)
where not exists (select 1 from public.carros);
