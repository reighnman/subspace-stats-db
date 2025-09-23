create or replace function league.update_season_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_round_number league.season_game.round_number%type
	,p_scheduled_timestamp league.season_game.scheduled_timestamp%type
)
returns void
language sql
as
$$

/*
*/

update league.season_game
set round_number = p_round_number
	,scheduled_timestamp = p_scheduled_timestamp
where season_game_id = p_season_game_id;

$$;

alter function league.update_season_game owner to ss_developer;

revoke all on function league.update_season_game from public;

grant execute on function league.update_season_game to ss_web_server;
