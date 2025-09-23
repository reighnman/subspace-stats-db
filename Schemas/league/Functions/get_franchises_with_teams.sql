create or replace function league.get_franchises_with_teams()
returns table(
	 franchise_id league.franchise.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
	,teams text
)
language sql
as
$$

/*
Gets all franchises with comma delimited teams.
For viewing the full list of franchises.

Usage:
select * from league.get_franchises_with_teams();
*/

select
	 f.franchise_id
	,f.franchise_name
	,string_agg(t.team_name, ', ' order by s.start_date) as teams
from league.franchise as f
left outer join league.team as t
	on f.franchise_id = t.franchise_id
left outer join league.season as s
	on t.season_id = s.season_id
group by f.franchise_id
order by f.franchise_name;

$$;

alter function league.get_franchises_with_teams owner to ss_developer;

revoke all on function league.get_franchises_with_teams from public;

grant execute on function league.get_franchises_with_teams to ss_web_server;
