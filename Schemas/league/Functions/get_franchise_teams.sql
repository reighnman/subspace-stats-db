create or replace function league.get_franchise_teams(
	 p_franchise_id league.franchise.franchise_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
)
language sql
as
$$

/*
Gets the teams that a franchise has participated as.

Usage:
select * from league.get_franchise_teams(3);

select * from league.franchise;
*/

select
	 t.team_id
	,t.team_name
	,s.season_id
	,s.season_name
from league.team as t
inner join league.season as s
	on t.season_id = s.season_id
where t.franchise_id = p_franchise_id
order by coalesce(s.start_date, s.created_timestamp);

$$;

alter function league.get_franchise_teams owner to ss_developer;

revoke all on function league.get_franchise_teams from public;

grant execute on function league.get_franchise_teams to ss_web_server;
