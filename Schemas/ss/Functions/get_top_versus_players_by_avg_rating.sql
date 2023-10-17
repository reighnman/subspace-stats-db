create or replace function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name player.player_name%type
	,avg_rating real
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by average rating for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.
p_min_games_played - The minimum # of games a player must have played to be included in the result.

Usage:
select * from get_top_versus_players_by_avg_rating(17, 5, 3);
select * from get_top_versus_players_by_avg_rating(17, 5);
*/

declare
	l_initial_rating stat_tracking.initial_rating%type;
begin
	if p_min_games_played < 1 then
		p_min_games_played := 1;
	end if;

	select st.initial_rating
	into l_initial_rating
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;

	if l_initial_rating is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		select
			 dt2.top_rank
			,p.player_name
			,dt2.avg_rating
		from(
			select
				 dense_rank() over(order by dt.avg_rating desc) as top_rank
				,dt.player_id
				,dt.avg_rating
			from(
				select
					 pr.player_id
					,(pr.rating - l_initial_rating)::real / pvs.games_played::real as avg_rating
				from player_versus_stats as pvs
				left outer join player_rating as pr
					on pvs.player_id = pr.player_id
						and pvs.stat_period_id = pr.stat_period_id
				where pvs.stat_period_id = p_stat_period_id
					and pvs.games_played >= coalesce(p_min_games_played, 1)
			) as dt
		) as dt2
		inner join player as p
			on dt2.player_id = p.player_id
		where dt2.top_rank <= p_top
		order by
			 dt2.top_rank
			,p.player_name;
end;
$$;

revoke all on function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) from public;

grant execute on function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) to ss_web_server;
