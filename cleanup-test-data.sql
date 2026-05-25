-- ============================================================================
--  THE MASK · remove the test data Claude created during the live audits
--  Run once in: Supabase dashboard -> SQL Editor -> New query -> paste -> Run.
--  It ONLY touches the test profile "zzAudit-test" and the test "Office League"
--  (invite code M8ATRH). Your real friends and their picks are left untouched.
-- ============================================================================

-- 1) Delete the test profile "zzAudit-test" and everything attached to it
--    (picks, prop answers, knockout/advance/re-picks, memberships, the login).
do $$
declare uid uuid;
begin
  select id into uid from profiles where display_name = 'zzAudit-test' limit 1;
  if uid is not null then
    delete from predictions  where user_id = uid;
    delete from prop_answers where user_id = uid;
    delete from advances     where user_id = uid;
    delete from ko_picks     where user_id = uid;
    delete from repicks      where user_id = uid;
    delete from memberships  where user_id = uid;
    delete from profiles     where id = uid;
    delete from auth.users   where id = uid;   -- also removes the anonymous login
  end if;
end $$;

-- 2) Delete the test league "Office League" (invite code M8ATRH) + any picks tagged to it.
--    (Its memberships are removed automatically by the foreign-key cascade.)
delete from predictions  where league_id in (select id from leagues where code = 'M8ATRH');
delete from prop_answers where league_id in (select id from leagues where code = 'M8ATRH');
delete from advances     where league_id in (select id from leagues where code = 'M8ATRH');
delete from ko_picks     where league_id in (select id from leagues where code = 'M8ATRH');
delete from repicks      where league_id in (select id from leagues where code = 'M8ATRH');
delete from leagues      where code = 'M8ATRH';

-- Done. If you spot any other stray test accounts in the profiles table, you can
-- remove them the same way as step 1 (swap 'zzAudit-test' for that display_name).
