create or replace function league.update_season_game_game_id(
	 p_season_game_id league.season_game.season_game_id%type
	,p_game_id league.season_game.game_id%type
)
returns void
language sql
as
$$

/*
*/

update league.season_game
set game_id = p_game_id
where season_game_id = p_season_game_id;

$$;

alter function league.update_season_game_game_id owner to ss_developer;

revoke all on function league.update_season_game_game_id from public;

grant execute on function league.update_season_game_game_id to ss_web_server;
grant execute on function league.update_season_game_game_id to ss_zone_server;
