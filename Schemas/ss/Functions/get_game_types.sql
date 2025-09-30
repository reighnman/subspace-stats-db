create or replace function ss.get_game_types()
returns table(
	 game_type_id ss.game_type.game_type_id%type
	,game_type_name ss.game_type.game_type_name%type
	,game_mode_id ss.game_type.game_mode_id%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Usage:
select * from ss.get_game_types();
*/

select
	 gt.game_type_id
	,gt.game_type_name
	,gt.game_mode_id
from ss.game_type as gt
order by gt.game_type_name;
$$;

alter function ss.get_game_types owner to ss_developer;

revoke all on function ss.get_game_types from public;

grant execute on function ss.get_game_types to ss_web_server;
