create or replace function league.get_leagues()
returns table(
	 league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
)
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
select * from league.get_leagues();
*/

select
	 l.league_id
	,l.league_name
	,l.game_type_id
from league.league as l;

$$;

alter function league.get_leagues owner to ss_developer;

revoke all on function league.get_leagues from public;

grant execute on function league.get_leagues to ss_web_server;
