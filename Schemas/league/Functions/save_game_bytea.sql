create or replace function league.save_game_bytea(
	 p_season_game_id league.season_game.season_game_id%type
	,p_game_json_utf8_bytes bytea
)
returns ss.game.game_id%type
language sql
as
$$

/*
This function wraps the save_game function so that data can be streamed to the database server.
At the moment npgsql only supports streaming of parameters using the bytea data type.
*/

select league.save_game(p_season_game_id, convert_from(p_game_json_utf8_bytes, 'UTF8')::jsonb);

$$;

alter function league.save_game_bytea owner to ss_developer;

revoke all on function league.save_game_bytea from public;

grant execute on function league.save_game_bytea to ss_zone_server;
