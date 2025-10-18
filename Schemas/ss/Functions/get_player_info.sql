create or replace function ss.get_player_info(
	p_player_name ss.player.player_name%type
)
returns table(
	 squad_name ss.squad.squad_name%type
	,x_res ss.player.x_res%type
	,y_res ss.player.y_res%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets information about a player.

Parameters:
p_player_name - The name of the player to get data about.

Usage:
select * from get_player_info('foo');
*/

select 
	 s.squad_name
	,p.x_res
	,p.y_res
from ss.player as p
left outer join ss.squad as s
	on p.squad_id = s.squad_id
where p.player_name = p_player_name;

$$;

alter function ss.get_player_info owner to ss_developer;

revoke all on function ss.get_player_info from public;

grant execute on function ss.get_player_info to ss_web_server;
