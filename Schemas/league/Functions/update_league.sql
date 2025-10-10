create or replace function league.update_league(
	 p_league_id league.league.league_id%type
	,p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
	,p_min_teams_per_game league.league.min_teams_per_game%type
	,p_max_teams_per_game league.league.max_teams_per_game%type
	,p_freq_start league.league.freq_start%type
	,p_freq_increment league.league.freq_increment%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.league
set  league_name = p_league_name
	,game_type_id = p_game_type_id
	,min_teams_per_game = p_min_teams_per_game
	,max_teams_per_game = p_max_teams_per_game
	,freq_start = p_freq_start
	,freq_increment = p_freq_increment
where league_id = p_league_id;

$$;

alter function league.update_league owner to ss_developer;

revoke all on function league.update_league from public;

grant execute on function league.update_league to ss_web_server;
