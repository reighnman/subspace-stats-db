create or replace function league.get_franchises_with_teams()
returns table(
	 franchise_id league.franchise.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
	,teams text
)
language sql
security definer
set search_path = league, pg_temp
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
	,(	select string_agg(dt.team_name, ', ' order by dt.last_used nulls last)
		from(
			select
				 t.team_name
				,max(s.start_date) as last_used
			from league.team as t
			inner join league.season as s
				on t.season_id = s.season_id
			where t.franchise_id = f.franchise_id
			group by t.team_name
		) as dt
	 ) as teams
from league.franchise as f
group by f.franchise_id
order by f.franchise_name;

$$;

alter function league.get_franchises_with_teams owner to ss_developer;

revoke all on function league.get_franchises_with_teams from public;

grant execute on function league.get_franchises_with_teams to ss_web_server;
