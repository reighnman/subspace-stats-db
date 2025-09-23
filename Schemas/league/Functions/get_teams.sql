create or replace function league.get_teams(
	p_season_id league.season.season_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
)
language sql
as
$$

/*
Usage:
select * from league.get_teams(2);
*/

select
	 t.team_id
	,t.team_name
from league.team as t
where t.season_id = p_season_id
order by t.team_name;

$$;

alter function league.get_teams owner to ss_developer;

revoke all on function league.get_teams from public;

grant execute on function league.get_teams to ss_web_server;
