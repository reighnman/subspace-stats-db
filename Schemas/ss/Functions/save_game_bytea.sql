create or replace function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type = null
)
returns game.game_id%type
language sql
as
$$

/*
This function wraps the save_game function so that data can be streamed to the database server.
At the moment npgsql only supports streaming of parameters using the bytea data type.
*/

select save_game(convert_from(p_game_json_utf8_bytes, 'UTF8')::jsonb, p_stat_period_id);

$$;

revoke all on function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type
) from public;

grant execute on function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type
) to ss_zone_server;
