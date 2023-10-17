create or replace function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
)
returns table(
	 player_name player.player_name%type
	,kills bigint
	,deaths bigint
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus kill stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get stats for.
p_stat_period_id - Id of the period to get stats for.
p_limit - The maximum # of records to return.

Usage:
select * from get_player_versus_kill_stats('foo', 16, 50);
select * from get_player_versus_kill_stats('bar', 16, 50);
select * from get_player_versus_kill_stats('G', 16, 50);
select * from get_player_versus_kill_stats('asdf', 16, 50);

select * from player;
select * from stat_period;
*/

declare
	l_player_id player.player_id%type;
	l_game_type_id game_type.game_type_id%type;
	l_period_range stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;
	
	if l_player_id is null then
		raise exception 'Invalid player name specified. (%)', p_player_name;
	end if;

	select
		 st.game_type_id
		,sp.period_range
	into
		 l_game_type_id
		,l_period_range
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;
	
	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		with cte_kill_history as (
			select
				 ke.killed_player_id
				,ke.killer_player_id
			from game as g
			inner join game_event as ge
				on g.game_id = ge.game_id
			inner join versus_game_kill_event as ke
				on ge.game_event_id = ke.game_event_id
			where g.game_type_id = l_game_type_id
				and g.time_played && l_period_range
				and ge.game_Event_type_id = 2 -- kill
				and (ke.killed_player_id = l_player_id or ke.killer_player_id = l_player_id)
				and ke.is_team_kill = false
		)
		select
			 p.player_name
			,dt3.kills
			,dt3.deaths
		from(
			select
				 coalesce(dt.player_id, dt2.player_id) as player_id
				,coalesce(dt.kills, 0) as kills
				,coalesce(dt2.deaths, 0) as deaths
			from(
				select
					 killed_player_id as player_id
					,count(*) as kills
				from cte_kill_history as h
				where killed_player_id <> l_player_id
				group by killed_player_id
			) as dt
			full join(
				select
					 killer_player_id as player_id
					,count(*) as deaths
				from cte_kill_history as h
				where killed_player_id = l_player_id
				group by killer_player_id
			) as dt2
				on dt.player_id = dt2.player_id
		) as dt3
		inner join player as p
			on dt3.player_id = p.player_id
		order by 
			 dt3.kills desc
			,dt3.deaths desc
			,p.player_name
		limit p_limit;
end;
$$;

revoke all on function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
) from public;

grant execute on function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
) to ss_web_server;
