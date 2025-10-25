create or replace function ss.get_or_upsert_squad(
	p_squad_name ss.squad.squad_name%type
)
returns ss.squad.squad_id%type
language plpgsql
as
$$

/*
select ss.get_or_upsert_squad('foo squad');
select ss.get_or_upsert_squad('foo squad');
select ss.get_or_upsert_squad('FOO squad');
select ss.get_or_upsert_squad('test');
select ss.get_or_upsert_squad('');
select ss.get_or_upsert_squad(' ');
select ss.get_or_upsert_squad(null);

select * from ss.squad;
*/

declare
	l_squad_id ss.squad.squad_id%type;
begin
	p_squad_name := trim(p_squad_name);
	if p_squad_name is null or trim(p_squad_name) = '' then
		return null;
	end if;

	select s.squad_id
	into l_squad_id
	from ss.squad as s
	where s.squad_name = p_squad_name; -- case insensitive
	
	if l_squad_id is null then
		insert into ss.squad(squad_name)
		values(p_squad_name)
		returning squad_id
		into l_squad_id;
	else
		update ss.squad
		set squad_name = p_squad_name
		where squad_id = l_squad_id
			and squad_name collate "default" <> p_squad_name collate "default"; -- case sensitive
	end if;
	
	return l_squad_id;
end;
$$;

alter function ss.get_or_upsert_squad owner to ss_developer;

revoke all on function ss.get_or_upsert_squad from public;
