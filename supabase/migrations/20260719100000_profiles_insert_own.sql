-- Allow authenticated users to create their own profile row
-- (AuthProvider ensureProfile heal path when trigger races or is missing).

create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check (
    id = auth.uid()
    and role = 'customer'
  );

grant insert on public.profiles to authenticated;
