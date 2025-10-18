create or replace function ss.get_or_insert_lvl(
	 p_lvl_file_name ss.lvl.lvl_file_name%type
	,p_lvl_checksum ss.lvl.lvl_checksum%type
)
returns ss.lvl.lvl_id%type
language plpgsql
as
$$

/*
Usage:
select ss.get_or_insert_lvl('foo.lvl', 123);
select ss.get_or_insert_lvl('foo.lvl', 1515);
select ss.get_or_insert_lvl('bar.lvl', 61261);

select * from ss.lvl
*/

declare
	l_lvl_id lvl.lvl_id%type;
begin
	select lvl_id
	into l_lvl_id
	from ss.lvl
	where lvl_file_name = p_lvl_file_name
		and lvl_checksum = p_lvl_checksum;
		
	if l_lvl_id is null then
		insert into ss.lvl(
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

alter function ss.get_or_insert_lvl owner to ss_developer;

revoke all on function ss.get_or_insert_lvl from public;
