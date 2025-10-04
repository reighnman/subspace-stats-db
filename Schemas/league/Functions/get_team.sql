create or replace function league.get_team(
	p_team_id league.team.team_id%type
)
returns table(
	 team_name league.team.team_name%type
	,season_id league.team.season_id%type
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
select * from league.get_team(1);
*/

select
	 t.team_name
	,t.season_id
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
from league.team as t
where t.team_id = p_team_id;

$$;

alter function league.get_team owner to ss_developer;

revoke all on function league.get_team from public;

grant execute on function league.get_team to ss_web_server;
