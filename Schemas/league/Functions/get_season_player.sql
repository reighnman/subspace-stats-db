create or replace function league.get_season_player(
	 p_season_id league.season.season_id%type
	,p_player_name ss.player.player_name%type
)
returns table(
	 player_id ss.player.player_id%type
	,player_name ss.player.player_name%type
	,team_id league.roster.team_id%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.get_season_player(2, 'foo');
*/

select
	 p.player_id
	,p.player_name -- sending this back so that the any case differences will be seen
	,r.team_id
	,r.is_captain
	,r.is_suspended
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = p_season_id
	and p.player_name = p_player_name;

$$;

alter function league.get_season_player owner to ss_developer;

revoke all on function league.get_season_player from public;

grant execute on function league.get_season_player to ss_web_server;
