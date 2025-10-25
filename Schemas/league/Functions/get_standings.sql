create or replace function league.get_standings(
	p_season_id league.season.season_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,wins league.team.wins%type
	,losses league.team.losses%type
	,draws league.team.draws%type
	-- TODO: Strength of Schedule (SOS)
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.get_standings(2);
*/

select
	 t.team_id
	,t.team_name
	,t.wins
	,t.losses
	,t.draws
from league.team as t
where t.season_id = p_season_id
order by 
	 (wins-losses) desc
	,draws desc
	,team_name

$$;

alter function league.get_standings owner to ss_developer;

revoke all on function league.get_standings from public;

grant execute on function league.get_standings to ss_web_server;
grant execute on function league.get_standings to ss_zone_server;
