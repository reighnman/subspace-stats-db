create or replace function league.delete_season_player(
	 p_season_id league.season.season_id%type
	,p_player_id ss.player.player_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.delete_season_player(2, 78);
select * 
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = 4
*/

delete from league.roster as r
where r.season_id = p_season_id
	and r.player_id = p_player_id;

$$;

alter function league.delete_season_player owner to ss_developer;

revoke all on function league.delete_season_player from public;

grant execute on function league.delete_season_player to ss_web_server;
