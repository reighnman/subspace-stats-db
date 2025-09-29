create or replace function league.get_season_teams(
	p_season_id league.season.season_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,banner_small league.team.banner_small%type
	,banner_large league.team.banner_large%type
	,is_enabled league.team.is_enabled%type
	,franchise_id league.team.franchise_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_teams(2);
*/

select
	 t.team_id
	,t.team_name
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
from league.team as t
where t.season_id = p_season_id
order by t.team_name;

$$;

alter function league.get_season_teams owner to ss_developer;

revoke all on function league.get_season_teams from public;

grant execute on function league.get_season_teams to ss_web_server;
