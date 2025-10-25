create or replace function ss.delete_game_type(
	 p_game_type_id ss.game_type.game_type_id%type
)
returns void
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

delete from ss.game_type
where game_type_id = p_game_type_id;

$$;

alter function ss.delete_game_type owner to ss_developer;

revoke all on function ss.delete_game_type from public;

grant execute on function ss.delete_game_type to ss_web_server;
