create or replace function league.get_team_id(
	 p_season_id league.team.season_id%type
	,p_team_name league.team.team_name%type
)
returns league.team.team_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the ID of a team by name.

Usage:
select league.get_team_id(2, 'one');
select league.get_team_id(2, 'ONE');
select league.get_team_id(2, 'Team 2');
select league.get_team_id(2, 'blah');
*/

select t.team_id
from league.team as t
where t.season_id = p_season_id
	and t.team_name = p_team_name;

$$;

alter function league.get_team_id owner to ss_developer;

revoke all on function league.get_team_id from public;

grant execute on function league.get_team_id to ss_web_server;
grant execute on function league.get_team_id to ss_zone_server;
