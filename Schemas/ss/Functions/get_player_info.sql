create or replace function ss.get_player_info(
	p_player_name character varying(20)
)
returns table(
	 squad_name squad.squad_name%type
	,x_res player.x_res%type
	,y_res player.y_res%type
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
from player as p
left outer join squad as s
	on p.squad_id = s.squad_id
where p.player_name = p_player_name;

$$;

revoke all on function ss.get_player_info(
	p_player_name character varying(20)
) from public;

grant execute on function ss.get_player_info(
	p_player_name character varying(20)
) to ss_web_server;
