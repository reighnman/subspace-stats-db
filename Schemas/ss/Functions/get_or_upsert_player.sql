create or replace function ss.get_or_upsert_player(
	 p_player_name ss.player.player_name%type
	,p_squad_name ss.squad.squad_name%type
	,p_x_res ss.player.x_res%type
	,p_y_res ss.player.y_res%type
)
returns ss.player.player_id%type
language plpgsql
as
$$

/*
Gets the player_id of a player by name.
If there is no record, INSERT one.

Player names are compared in a case-insensitive manner.
If there is a record, UPDATE the name to match if there is a difference in upper/lower case.
This way, we remember the name in the form it was last used.

Usage:
select ss.get_or_upsert_player('foo', null, 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', 'test', 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', 'the best squad', 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', null, 1920::smallint, 1080::smallint);
select ss.get_or_upsert_player('FOO', null, 1024::smallint, 768::smallint);
select ss.get_or_upsert_player(' ', null, 1024::smallint, 768::smallint);

select * from ss.player;
select * from ss.squad;
*/

declare
	l_player_id ss.player.player_id%type;
	l_squad_id ss.squad.squad_id%type;
begin
	p_player_name := trim(p_player_name);
	if p_player_name is null or p_player_name = '' then
		return null;
	end if;

	l_squad_id := ss.get_or_upsert_squad(p_squad_name);
	
	merge into ss.player as p
	using(
		select
			 p_player_name as player_name
			,l_squad_id as squad_id
			,p_x_res as x_res
			,p_y_res as y_res
	) as t on p.player_name = t.player_name -- case insensitive
	when not matched then
		insert(
			 player_name
			,squad_id
			,x_res
			,y_res
		)
		values(
			 t.player_name
			,t.squad_id
			,t.x_res
			,t.y_res
		)
	when matched 
		and(   p.player_name collate "default" <> t.player_name collate "default" -- case sensitive
			or not(nullif(p.squad_id, t.squad_id) is null and nullif(t.squad_id, p.squad_id) is null)
			or not(nullif(p.x_res, t.x_res) is null and nullif(t.x_res, p.x_res) is null)
			or not(nullif(p.y_res, t.y_res) is null and nullif(t.y_res, p.y_res) is null)
		) 
		then
		update set
			 player_name = t.player_name
			,squad_id = t.squad_id
			,x_res = t.x_res
			,y_res = t.y_res;
		
	select player_id
	into l_player_id
	from ss.player
	where player_name = p_player_name; -- case insensitive

	return l_player_id;
end;
$$;

alter function ss.get_or_upsert_player owner to ss_developer;

revoke all on function ss.get_or_upsert_player from public;
