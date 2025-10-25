create or replace function ss.insert_game_type(
	 p_game_type_name ss.game_type.game_type_name%type
	,p_game_mode_id ss.game_type.game_mode_id%type
)
returns ss.game_type.game_type_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

insert into ss.game_type(
	 game_type_name
	,game_mode_id
)
values(
	 p_game_type_name
	,p_game_mode_id
)
returning
	 game_type_id;

$$;

alter function ss.insert_game_type owner to ss_developer;

revoke all on function ss.insert_game_type from public;

grant execute on function ss.insert_game_type to ss_web_server;
