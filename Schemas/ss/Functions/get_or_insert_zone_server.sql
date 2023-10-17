create or replace function ss.get_or_insert_zone_server(
	p_zone_server_name character varying
)
returns bigint
language plpgsql
as
$$
declare
	l_zone_server_id bigint;
begin
	select zs.zone_server_id
	into l_zone_server_id
	from zone_server as zs
	where zs.zone_server_name = p_zone_server_name;
	
	if l_zone_server_id is null then
		insert into zone_server(zone_server_name)
		values(p_zone_server_name)
		returning zone_server_id
		into l_zone_server_id;
	end if;
	
	return l_zone_server_id;
end;
$$;
