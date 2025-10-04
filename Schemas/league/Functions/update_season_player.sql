create or replace function league.update_season_player(
	 p_season_id league.season.season_id%type
	,p_player_id ss.player.player_id%type
	,p_team_id league.roster.team_id%type
	,p_is_captain league.roster.is_captain%type
	,p_is_suspended league.roster.is_suspended%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.update_season_player(2, 78, null, true, false);
*/

update league.roster as r
set team_id = p_team_id
	,is_captain = p_is_captain
	,is_suspended = p_is_suspended
where r.season_id = p_season_id
	and r.player_id = p_player_id;

$$;

alter function league.update_season_player owner to ss_developer;

revoke all on function league.update_season_player from public;

grant execute on function league.update_season_player to ss_web_server;
