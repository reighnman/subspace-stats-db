create or replace function league.get_season_rosters(
	p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage
select league.get_season_rosters(2);
*/

select json_agg(dt)
from(
	select
		 t.team_id
		,t.team_name
		,t.banner_small
		,t.banner_large
		,(select coalesce(json_agg(get_team_roster), '[]'::json) from league.get_team_roster(t.team_id)) as roster
	from league.team as t
	where t.season_id = p_season_id
		and t.is_enabled
	order by t.team_name
) as dt;

$$;

alter function league.get_season_rosters owner to ss_developer;

revoke all on function league.get_season_rosters from public;

grant execute on function league.get_season_rosters to ss_web_server;
