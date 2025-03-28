create or replace function ss.refresh_player_versus_stats(
	p_stat_period_id stat_period.stat_period_id%type
)
returns void
language plpgsql
as
$$

/*
Refreshes the stats of players for a specified team versus stat period from game data.
Through normal operation, the save_game function will automatically record to the player_versus_stats table.
This function can be used to manually refresh the data if needed.
For example, if you were to add a stat period for a period_range that includes past games.
Or, if for some reason you suspect player_versus_stat data is out of sync with game data.

Use this with caution, as it can result in a long running operation.
For example, if you specify a 'forever' period it will need to read every game record 
matching the stat period's game type, which will likely be very large # of records to process.

Parameters:
p_stat_period_id - Id of the stat period to refresh player stat data for.

Usage:
select ss.refresh_player_versus_stats(18);

select * from stat_period;
select * from stat_tracking;
select * from player_rating;
*/

declare
	l_game_type_id game_type.game_type_id%type;
	l_period_range stat_period.period_range%type;
	l_is_rating_enabled stat_tracking.is_rating_enabled%type;
	l_initial_rating stat_tracking.initial_rating%type;
	l_minimum_rating stat_tracking.minimum_rating%type;
begin
	select
		 st.game_type_id
		,sp.period_range
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	into
		 l_game_type_id
		,l_period_range
		,l_is_rating_enabled
		,l_initial_rating
		,l_minimum_rating
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;
	
	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	delete from player_versus_stats
	where stat_period_id = p_stat_period_id;
	
	insert into player_versus_stats(
		 player_id
		,stat_period_id
		,games_played
		,play_duration
		,wins
		,losses
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out_regular
		,first_out_critical
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
	)
	select
		 dt.player_id
		,p_stat_period_id
		,count(distinct dt.game_id) as games_played
		,sum(dt.play_duration) as play_duration
		,count(*) filter(where dt.is_winner) as wins
		,count(*) filter(where dt.is_loser) as losses
		,sum(dt.lag_outs) as lag_outs
		,sum(dt.kills) as kills
		,sum(dt.deaths) as deaths
		,sum(dt.knockouts) as knockouts
		,sum(dt.team_kills) as team_kills
		,sum(dt.solo_kills) as solo_kills
		,sum(dt.assists) as assists
		,sum(dt.forced_reps) as forced_reps
		,sum(dt.gun_damage_dealt) as gun_damage_dealt
		,sum(dt.bomb_damage_dealt) as bomb_damage_dealt
		,sum(dt.team_damage_dealt) as team_damage_dealt
		,sum(dt.gun_damage_taken) as gun_damage_taken
		,sum(dt.bomb_damage_taken) as bomb_damage_taken
		,sum(dt.team_damage_taken) as team_damage_taken
		,sum(dt.self_damage) as self_damage
		,sum(dt.kill_damage) as kill_damage
		,sum(dt.team_kill_damage) as team_kill_damage
		,sum(dt.forced_rep_damage) as forced_rep_damage
		,sum(dt.bullet_fire_count) as bullet_fire_count
		,sum(dt.bomb_fire_count) as bomb_fire_count
		,sum(dt.mine_fire_count) as mine_fire_count
		,sum(dt.bullet_hit_count) as bullet_hit_count
		,sum(dt.bomb_hit_count) as bomb_hit_count
		,sum(dt.mine_hit_count) as mine_hit_count
		,count(*) filter(where dt.first_out_regular) as first_out_regular
		,count(*) filter(where dt.first_out_critical) as first_out_critical
		,sum(dt.wasted_energy) as wasted_energy
		,sum(dt.wasted_repel) as wasted_repel
		,sum(dt.wasted_rocket) as wasted_rocket
		,sum(dt.wasted_thor) as wasted_thor
		,sum(dt.wasted_burst) as wasted_burst
		,sum(dt.wasted_decoy) as wasted_decoy
		,sum(dt.wasted_portal) as wasted_portal
		,sum(dt.wasted_brick) as wasted_brick
		,sum(enemy_distance_sum) as enemy_distance_sum
		,sum(enemy_distance_samples) as enemy_distance_samples
		,sum(team_distance_sum) as team_distance_sum
		,sum(team_distance_samples) as team_distance_samples
	from(
		select
			 vgtm.game_id
			,vgtm.player_id
			,vgt.is_winner
			,case when exists(
					select *
					from versus_game_team as vgt2
					where vgt2.game_id = vgtm.game_id
						and vgt2.freq <> vgt.freq
						and vgt2.is_winner = true
				 )
				 then true
				 else false
			 end as is_loser
			,vgtm.play_duration
			,vgtm.lag_outs
			,vgtm.kills
			,vgtm.deaths
			,vgtm.knockouts
			,vgtm.team_kills
			,vgtm.solo_kills
			,vgtm.assists
			,vgtm.forced_reps
			,vgtm.gun_damage_dealt
			,vgtm.bomb_damage_dealt
			,vgtm.team_damage_dealt
			,vgtm.gun_damage_taken
			,vgtm.bomb_damage_taken
			,vgtm.team_damage_taken
			,vgtm.self_damage
			,vgtm.kill_damage
			,vgtm.team_kill_damage
			,vgtm.forced_rep_damage
			,vgtm.bullet_fire_count
			,vgtm.bomb_fire_count
			,vgtm.mine_fire_count
			,vgtm.bullet_hit_count
			,vgtm.bomb_hit_count
			,vgtm.mine_hit_count
			,case when vgtm.first_out = 1 then true else false end as first_out_regular
			,case when vgtm.first_out = 2 then true else false end as first_out_critical
			,vgtm.wasted_energy
			,vgtm.wasted_repel
			,vgtm.wasted_rocket
			,vgtm.wasted_thor
			,vgtm.wasted_burst
			,vgtm.wasted_decoy
			,vgtm.wasted_portal
			,vgtm.wasted_brick
			,enemy_distance_sum
			,enemy_distance_samples
			,team_distance_sum
			,team_distance_samples
		from game as g
		inner join versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
		inner join versus_game_team as vgt
			on vgtm.game_id = vgt.game_id
				and vgtm.freq = vgt.freq
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
	) as dt
	group by dt.player_id;

	if l_is_rating_enabled = true then
		delete from player_rating
		where stat_period_id = p_stat_period_id;

		insert into player_rating(
			 player_id
			,stat_period_id
			,rating
		)
		select
			 vgtm.player_id
			,p_stat_period_id
			,greatest(l_initial_rating + sum(vgtm.rating_change), l_minimum_rating) as rating
		from game as g
		inner join versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
		group by vgtm.player_id;
	end if;
end;
$$;