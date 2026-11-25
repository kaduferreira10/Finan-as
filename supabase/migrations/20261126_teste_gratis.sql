-- Teste grátis de 7 dias (26/11/2026)
-- Quem já é cliente não muda nada: teste_ate fica vazio e vale o "ativo" de sempre.
-- Conta convidada pelo painel (Send invitation) nasce ativa, como antes.
-- Conta criada de qualquer outro jeito (cadastro no app, "Create new user" no painel)
-- nasce com 7 dias de teste. Para liberar de vez, marque ativo = true na tabela assinantes.

alter table public.assinantes add column if not exists teste_ate timestamptz;

create or replace function public.assinante_ativo()
 returns boolean language sql stable security definer set search_path to 'public'
as $$
  select exists (
    select 1 from assinantes
    where user_id = auth.uid()
      and (ativo or (teste_ate is not null and teste_ate > now()))
  )
$$;

create or replace function public.novo_assinante()
 returns trigger language plpgsql security definer set search_path to 'public'
as $$
begin
  insert into public.assinantes (user_id, email, ativo, teste_ate)
  values (
    new.id, new.email,
    new.invited_at is not null,
    case when new.invited_at is null then now() + interval '7 days' end
  )
  on conflict do nothing;
  return new;
end;
$$;

-- mantém as permissões (create or replace já preserva; reforço por garantia)
revoke execute on function public.novo_assinante() from public, anon, authenticated;
revoke execute on function public.assinante_ativo() from public, anon;
grant execute on function public.assinante_ativo() to authenticated;
