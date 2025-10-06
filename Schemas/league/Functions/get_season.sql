create or replace function league.get_season(
	 p_season_id league.season.season_id%type
)
returns table(
	 season_name league.season.season_name%type
	,league_id league.league.league_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season(2);
*/

select
	 s.season_name
	,l.league_id
from league.season as s
where s.season_id = p_season_id;

$$;

alter function league.get_season owner to ss_developer;

revoke all on function league.get_season from public;

grant execute on function league.get_season to ss_web_server;
