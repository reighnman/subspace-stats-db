create or replace function league.get_league(
	 p_league_id league.league.league_id%type
)
returns table(
	 league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
	,min_teams_per_game league.league.min_teams_per_game%type
	,max_teams_per_game league.league.max_teams_per_game%type
	,freq_start league.league.freq_start%type
	,freq_increment league.league.freq_increment%type
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
	,min_teams_per_game
	,max_teams_per_game
	,freq_start
	,freq_increment
from league.league as l
where l.league_id = p_league_id;

$$;

alter function league.get_league owner to ss_developer;

revoke all on function league.get_league from public;

grant execute on function league.get_league to ss_web_server;
