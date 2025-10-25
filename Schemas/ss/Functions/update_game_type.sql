create or replace function ss.update_game_type(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_game_type_name ss.game_type.game_type_name%type
	,p_game_mode_id ss.game_type.game_mode_id%type
)
returns void
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

update ss.game_type
set	 game_type_name = p_game_type_name
	,game_mode_id = p_game_mode_id
where game_type_id = p_game_type_id;

$$;

alter function ss.update_game_type owner to ss_developer;

revoke all on function ss.update_game_type from public;

grant execute on function ss.update_game_type to ss_web_server;
