create or replace function ss.get_or_insert_arena(
	p_arena_name arena.arena_name%type
)
returns arena.arena_id%type
language plpgsql
as
$$

/*
Usage:
select get_or_insert_arena('turf');
select get_or_insert_arena('TURF2');
select get_or_insert_arena('turf1');
select get_or_insert_arena('turf2');
select get_or_insert_arena('0');
select get_or_insert_arena('1');
select get_or_insert_arena('4v4pub');
select get_or_insert_arena('4v4pub1');
select get_or_insert_arena('4v4pub2');
select get_or_insert_arena('pb');

select * from arena;
*/

declare
	l_arena_id arena.arena_id%type;
begin
	-- no matter what, arena names should always be lowercase
	p_arena_name := lower(p_arena_name);

	select a.arena_id
	into l_arena_id
	from arena as a
	where a.arena_name = p_arena_name;
	
	if l_arena_id is null then
		insert into arena(arena_name)
		values(p_arena_name)
		returning arena_id
		into l_arena_id;
	end if;
	
	return l_arena_id;
end;
$$;
