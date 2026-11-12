-- Depois de criares o utilizador em Authentication → Users,
-- troca o email abaixo pelo email desse utilizador e carrega em "Run".
insert into public.admins (user_id)
select id from auth.users where email = 'EMAIL-DO-ADMIN@exemplo.pt'
on conflict do nothing;
