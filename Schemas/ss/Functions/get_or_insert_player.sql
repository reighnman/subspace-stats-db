create or replace function ss.get_or_insert_player(
	 p_player_name ss.player.player_name%type
)
returns ss.player.player_id%type
language plpgsql
as
$$

/*
Gets the player_id of a player by name.
If there is no record, INSERT one.
Player names are compared in a case-insensitive manner.

Usage:
select ss.get_or_insert_player('foo');
select ss.get_or_insert_player('bar');

select * from ss.player;
select * from ss.squad;
*/

declare
	l_player_id ss.player.player_id%type;
begin
	p_player_name := trim(p_player_name);
	if p_player_name is null or p_player_name = '' then
		return null;
	end if;

	insert into ss.player(player_name)
	select p_player_name
	where not exists(
			select *
			from ss.player as p
			where p.player_name = p_player_name
		);
		
	select player_id
	into l_player_id
	from ss.player
	where player_name = p_player_name;

	return l_player_id;
end;
$$;

alter function ss.get_or_insert_player owner to ss_developer;

revoke all on function ss.get_or_insert_player from public;
