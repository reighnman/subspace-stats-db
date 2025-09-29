create or replace function league.update_league(
	 p_league_id league.league.league_id%type
	,p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
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
where league_id = p_league_id;

$$;

alter function league.update_league owner to ss_developer;

revoke all on function league.update_league from public;

grant execute on function league.update_league to ss_web_server;
