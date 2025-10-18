create or replace function ss.get_or_insert_zone_server(
	p_zone_server_name ss.zone_server.zone_server_name%type
)
returns ss.zone_server.zone_server_id%type
language plpgsql
as
$$
declare
	l_zone_server_id ss.zone_server.zone_server_id%type;
begin
	select zs.zone_server_id
	into l_zone_server_id
	from ss.zone_server as zs
	where zs.zone_server_name = p_zone_server_name;
	
	if l_zone_server_id is null then
		insert into ss.zone_server(zone_server_name)
		values(p_zone_server_name)
		returning zone_server_id
		into l_zone_server_id;
	end if;
	
	return l_zone_server_id;
end;
$$;

alter function ss.get_or_insert_zone_server owner to ss_developer;

revoke all on function ss.get_or_insert_zone_server from public;
