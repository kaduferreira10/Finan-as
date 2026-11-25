-- Ajustes de desempenho e segurança (25/11/2026)
-- Mesmo comportamento de acesso: cada usuário vê só os próprios dados E precisa de assinatura ativa.
-- Muda só a forma de cálculo: (select auth.uid()) e (select assinante_ativo()) são avaliados uma vez por consulta.

-- 1) Regras "dono" (permissivas)
drop policy if exists "dono" on public.lancamentos;
create policy "dono" on public.lancamentos as permissive for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "dono" on public.categorias;
create policy "dono" on public.categorias as permissive for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "dono" on public.contas;
create policy "dono" on public.contas as permissive for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "dono" on public.planos;
create policy "dono" on public.planos as permissive for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "dono" on public.previsoes;
create policy "dono" on public.previsoes as permissive for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "ver o proprio status" on public.assinantes;
create policy "ver o proprio status" on public.assinantes as permissive for select to authenticated
  using (user_id = (select auth.uid()));

-- 2) Regras de assinatura (restritivas: precisam valer junto com "dono")
drop policy if exists "so assinante ativo" on public.lancamentos;
create policy "so assinante ativo" on public.lancamentos as restrictive for all to authenticated
  using ((select public.assinante_ativo())) with check ((select public.assinante_ativo()));

drop policy if exists "so assinante ativo" on public.categorias;
create policy "so assinante ativo" on public.categorias as restrictive for all to authenticated
  using ((select public.assinante_ativo())) with check ((select public.assinante_ativo()));

drop policy if exists "assinante" on public.contas;
create policy "assinante" on public.contas as restrictive for all to authenticated
  using ((select public.assinante_ativo())) with check ((select public.assinante_ativo()));

drop policy if exists "assinante" on public.planos;
create policy "assinante" on public.planos as restrictive for all to authenticated
  using ((select public.assinante_ativo())) with check ((select public.assinante_ativo()));

drop policy if exists "assinante" on public.previsoes;
create policy "assinante" on public.previsoes as restrictive for all to authenticated
  using ((select public.assinante_ativo())) with check ((select public.assinante_ativo()));

-- 3) Índices que faltavam
create index if not exists contas_user_id_idx on public.contas (user_id);
create index if not exists planos_user_id_idx on public.planos (user_id);

-- 4) Funções: novo_assinante só roda como gatilho; assinante_ativo só para usuários logados
revoke execute on function public.novo_assinante() from public, anon, authenticated;
revoke execute on function public.assinante_ativo() from public, anon;
grant execute on function public.assinante_ativo() to authenticated;
