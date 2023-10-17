create or replace function ss.get_or_upsert_squad(
	p_squad_name squad.squad_name%type
)
returns squad.squad_id%type
language plpgsql
as
$$

/*
select get_or_upsert_squad('foo squad');
select get_or_upsert_squad('foo squad');
select get_or_upsert_squad('FOO squad');
select get_or_upsert_squad('test');
select get_or_upsert_squad('');
select get_or_upsert_squad(' ');
select get_or_upsert_squad(null);

select * from squad;
*/

declare
	l_squad_id squad.squad_id%type;
begin
	p_squad_name := trim(p_squad_name);
	if p_squad_name is null or trim(p_squad_name) = '' then
		return null;
	end if;

	select s.squad_id
	into l_squad_id
	from squad as s
	where s.squad_name = p_squad_name; -- case insensitive
	
	if l_squad_id is null then
		insert into squad(squad_name)
		values(p_squad_name)
		returning squad_id
		into l_squad_id;
	else
		update squad
		set squad_name = p_squad_name
		where squad_id = l_squad_id
			and squad_name collate "default" <> p_squad_name collate "default"; -- case sensitive
	end if;
	
	return l_squad_id;
end;
$$;