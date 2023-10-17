create or replace function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
)
returns table(
	 player_name player.player_name%type
	,rating player_rating.rating%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the rating of a specified list of players for a the latest available stat period of a game type.

Parameters:
p_game_type_id - The type of game to get ratings for.
p_player_names - The names of the players to get data for.

Usage:
select * from ss.get_player_rating(2, '{"foo", "bar", "baz", "asdf"}');

select * from player_rating
*/

select
	 t.player_name
 	,coalesce(pr.rating, dt.initial_rating) as rating
from(
	select
		 sp.stat_period_id
		,st.initial_rating
	from stat_tracking as st
	inner join stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
	where st.game_type_id = p_game_type_id
		and st.is_rating_enabled = true
	order by
		 st.is_auto_generate_period desc
		,sp.period_range desc -- compares by lower bound first, then upper bound
	limit 1
) as dt
cross join unnest(p_player_names) as t(player_name)
left outer join player as p
	on t.player_name = p.player_name
left outer  join player_rating as pr
	on p.player_id = pr.player_id
		and dt.stat_period_id = pr.stat_period_id;

$$;

revoke all on function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
) from public;

grant execute on function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
) to ss_zone_server;
