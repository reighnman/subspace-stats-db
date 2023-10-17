create or replace function ss.get_or_insert_lvl(
	 p_lvl_file_name lvl.lvl_file_name%type
	,p_lvl_checksum lvl.lvl_checksum%type
)
returns lvl.lvl_id%type
language plpgsql
as
$$

/*
Usage:
select get_or_insert_lvl('foo.lvl', 123);
select get_or_insert_lvl('foo.lvl', 1515);
select get_or_insert_lvl('bar.lvl', 61261);

select * from lvl
*/

declare
	l_lvl_id lvl.lvl_id%type;
begin
	select lvl_id
	into l_lvl_id
	from lvl
	where lvl_file_name = p_lvl_file_name
		and lvl_checksum = p_lvl_checksum;
		
	if l_lvl_id is null then
		insert into lvl(
			 lvl_file_name
			,lvl_checksum
		)
		values(
			 p_lvl_file_name
			,p_lvl_checksum
		)
		returning lvl_id
		into l_lvl_id;
	end if;
	
	return l_lvl_id;
end;
$$;
