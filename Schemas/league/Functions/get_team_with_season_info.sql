create or replace function league.get_team_with_season_info(
	p_team_id league.team.team_id%type
)
returns table(
	 team_name league.team.team_name%type
	,banner_small league.team.banner_small%type
	,banner_large league.team.banner_large%type
	,is_enabled league.team.is_enabled%type
	,franchise_id league.team.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,wins league.team.wins%type
	,losses league.team.losses%type
	,draws league.team.draws%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_team_with_season_info(1);
*/

select
	 t.team_name
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
	,f.franchise_name
	,l.league_id
	,l.league_name
	,s.season_id
	,s.season_name
	,t.wins
	,t.losses
	,t.draws
from league.team as t
inner join league.season as s
	on t.season_id = s.season_id
inner join league.league as l
	on s.league_id = l.league_id
left outer join league.franchise as f
	on t.franchise_id = f.franchise_id
where t.team_id = p_team_id;

$$;

alter function league.get_team_with_season_info owner to ss_developer;

revoke all on function league.get_team_with_season_info from public;

grant execute on function league.get_team_with_season_info to ss_web_server;
