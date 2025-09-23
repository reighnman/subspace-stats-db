create or replace function league.get_seasons(
	 p_league_id league.league.league_id%type
)
returns table(
	 season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,created_timestamp league.season.created_timestamp%type
)
language sql
as
$$

/*
Usage:
select * from league.get_seasons(13);
select * from league.league;
*/

select
	 s.season_id
	,s.season_name
	,s.created_timestamp
from league.season as s
where s.league_id = p_league_id
order by s.created_timestamp desc;

$$;

alter function league.get_seasons owner to ss_developer;

revoke all on function league.get_seasons from public;

grant execute on function league.get_seasons to ss_web_server;
