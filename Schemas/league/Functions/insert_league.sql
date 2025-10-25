create or replace function league.insert_league(
	 p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
	,p_min_teams_per_game league.league.min_teams_per_game%type
	,p_max_teams_per_game league.league.max_teams_per_game%type
	,p_freq_start league.league.freq_start%type
	,p_freq_increment league.league.freq_increment%type
)
returns league.league.league_id%type
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
Usage:
select * from league.insert_league('SVS Pro League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Intermediate League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Amateur League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS United League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Draft League', 12, 2, 2, 10, 10);
select * from league.insert_league('Test 2v2 league', 2, 2, 2, 10, 10);

select * from league.league;
*/

insert into league.league(
	 league_name
	,game_type_id
	,min_teams_per_game
	,max_teams_per_game
	,freq_start
	,freq_increment
)
values(
	 p_league_name
	,p_game_type_id
	,p_min_teams_per_game
	,p_max_teams_per_game
	,p_freq_start
	,p_freq_increment
)
returning
	 league_id;

$$;

alter function league.insert_league owner to ss_developer;

revoke all on function league.insert_league from public;

grant execute on function league.insert_league to ss_web_server;