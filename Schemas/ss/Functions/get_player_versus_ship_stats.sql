create or replace function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
)
returns table(
	 ship_type smallint
	,game_use_count integer
	,use_duration interval
	,kills bigint
	,deaths bigint
	,knockouts bigint
	,solo_kills bigint
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's versus game ship stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get stats for.
p_stat_period_id - Id of the stat period to get data for.

Usage:
select * from get_player_versus_ship_stats('foo', 16);
select * from get_player_versus_ship_stats('bar', 16);
select * from get_player_versus_ship_stats('bar', 17);
select * from get_player_versus_ship_stats('asdf', 16);
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
		with cte_kill_history as(
			select
				 ke.game_event_id
				,ke.killed_player_id
				,ke.killer_player_id
				,ke.is_knockout
				,ke.is_team_kill
				,killed_ship
				,killer_ship
			from game as g
			inner join game_event as ge
					on g.game_id = ge.game_id
				inner join versus_game_kill_event as ke
					on ge.game_event_id = ke.game_event_id
			where g.game_type_id = l_game_type_id
				and g.time_played && l_period_range
				and ge.game_Event_type_id = 2 -- kill
				and (ke.killed_player_id = l_player_id or ke.killer_player_id = l_player_id)
		)
		select
			 dt.ship
			,dt.game_use_count
			,dt.use_duration
			,coalesce(dt3.kills, 0) as kills
			,coalesce(dt2.deaths, 0) as deaths
			,coalesce(dt3.knockouts, 0) as knockouts
			,coalesce(dt3.solo_kills, 0) as solo_kills
		from(
			select
				 0::smallint as ship -- warbird
				,u.warbird_use as game_use_count
				,u.warbird_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 1::smallint -- javelin
				,u.javelin_use as game_use_count
				,u.javelin_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 2::smallint -- spider
				,u.spider_use as game_use_count
				,u.spider_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 3::smallint -- leviathan
				,u.leviathan_use as game_use_count
				,u.leviathan_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 4::smallint -- terrier
				,u.terrier_use as game_use_count
				,u.terrier_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 5::smallint -- weasel
				,u.weasel_use as game_use_count
				,u.weasel_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 6::smallint -- lancaster
				,u.lancaster_use as game_use_count
				,u.lancaster_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 7::smallint -- shark
				,u.shark_use as game_use_count
				,u.shark_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
		) as dt
		left outer join(
			select
				 h.killed_ship as ship
				,count(*) as deaths
			from cte_kill_history as h
			where killed_player_id = l_player_id
				-- purposely including deaths that were team kills
			group by h.killed_ship
		) as dt2
			on dt.ship = dt2.ship
		left outer join(
			select
				 h.killer_ship as ship
				,count(*) as kills
				,sum(case when h.is_knockout = true then 1 else 0 end) as knockouts
				,sum(
					case when exists(
							select * 
							from game_event_damage as d
							where d.game_event_id = h.game_event_id
								and player_id <> l_player_id
						)
						then 0
						else 1
					end
				) as solo_kills
			from cte_kill_history as h
			where h.killer_player_id = l_player_id
				and h.is_team_kill = false -- not including team kills
			group by h.killer_ship
		) as dt3
			on dt.ship = dt3.ship
		order by dt.ship;
end;
$$;

revoke all on function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
) from public;

grant execute on function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
) to ss_web_server;
