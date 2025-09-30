create or replace function league.get_league(
	 p_league_id league.league.league_id%type
)
returns table(
	 league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
)
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
Usage:
select * from league.get_league(13);
*/

select
	 l.league_name
	,l.game_type_id
from league.league as l
where l.league_id = p_league_id;

$$;

alter function league.get_league owner to ss_developer;

revoke all on function league.get_league from public;

grant execute on function league.get_league to ss_web_server;
