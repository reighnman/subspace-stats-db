create or replace function ss.get_player_versus_game_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_id ss.stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 game_id ss.game.game_id%type
	,time_played ss.game.time_played%type
	,score integer[]
	,result integer
	,play_duration ss.versus_game_team_member.play_duration%type
	,ship_mask ss.versus_game_team_member.ship_mask%type
	,lag_outs ss.versus_game_team_member.lag_outs%type
	,kills ss.versus_game_team_member.kills%type
	,deaths ss.versus_game_team_member.deaths%type
	,knockouts ss.versus_game_team_member.knockouts%type
	,team_kills ss.versus_game_team_member.team_kills%type
	,solo_kills ss.versus_game_team_member.solo_kills%type
	,assists ss.versus_game_team_member.assists%type
	,forced_reps ss.versus_game_team_member.forced_reps%type
	,gun_damage_dealt ss.versus_game_team_member.gun_damage_dealt%type
	,bomb_damage_dealt ss.versus_game_team_member.bomb_damage_dealt%type
	,team_damage_dealt ss.versus_game_team_member.team_damage_dealt%type
	,gun_damage_taken ss.versus_game_team_member.gun_damage_taken%type
	,bomb_damage_taken ss.versus_game_team_member.bomb_damage_taken%type
	,team_damage_taken ss.versus_game_team_member.team_damage_taken%type
	,self_damage ss.versus_game_team_member.self_damage%type
	,kill_damage ss.versus_game_team_member.kill_damage%type
	,team_kill_damage ss.versus_game_team_member.team_kill_damage%type
	,forced_rep_damage ss.versus_game_team_member.forced_rep_damage%type
	,bullet_fire_count ss.versus_game_team_member.bullet_fire_count%type
	,bomb_fire_count ss.versus_game_team_member.bomb_fire_count%type
	,mine_fire_count ss.versus_game_team_member.mine_fire_count%type
	,bullet_hit_count ss.versus_game_team_member.bullet_hit_count%type
	,bomb_hit_count ss.versus_game_team_member.bomb_hit_count%type
	,mine_hit_count ss.versus_game_team_member.mine_hit_count%type
	,first_out ss.versus_game_team_member.first_out%type
	,wasted_energy ss.versus_game_team_member.wasted_energy%type
	,wasted_repel ss.versus_game_team_member.wasted_repel%type
	,wasted_rocket ss.versus_game_team_member.wasted_rocket%type
	,wasted_thor ss.versus_game_team_member.wasted_thor%type
	,wasted_burst ss.versus_game_team_member.wasted_burst%type
	,wasted_decoy ss.versus_game_team_member.wasted_decoy%type
	,wasted_portal ss.versus_game_team_member.wasted_portal%type
	,wasted_brick ss.versus_game_team_member.wasted_brick%type
	,rating_change ss.versus_game_team_member.rating_change%type
	,enemy_distance_sum ss.versus_game_team_member.enemy_distance_sum%type
	,enemy_distance_samples ss.versus_game_team_member.enemy_distance_samples%type
	,team_distance_sum ss.versus_game_team_member.team_distance_sum%type
	,team_distance_samples ss.versus_game_team_member.team_distance_samples%type
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus game stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get data for.
p_stat_period_id - The period to get data for.
p_limit - The maximum # of game records to return.
p_offset - The offset of the game records to return.

Usage:
select * from ss.get_player_versus_game_stats('foo', 16, 100, 0);
select * from ss.get_player_versus_game_stats('foo', 16, 2, 2);

select * from ss.stat_period
*/

declare
	l_player_id ss.player.player_id%type;
	l_game_type_id ss.game_type.game_type_id%type;
	l_period_range ss.stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from ss.player as p
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
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	inner join ss.game_type as gt
		on st.game_type_id = gt.game_type_id
	where sp.stat_period_id = p_stat_period_id
		and gt.game_mode_id = 2; -- Team Versus
	
	if l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	return query
		select
			 g.game_id
			,g.time_played
			,array(
				select vgt.score
				from ss.versus_game_team as vgt
				where vgt.game_id = vgtm.game_id
				order by freq
			) as score
			,case when exists(
					select *
					from ss.versus_game_team as vgt
					where vgt.game_id = vgtm.game_id
						and vgt.freq = vgtm.freq
						and vgt.is_winner
				)
				then 1 -- win
				else case when exists(
						select *
						from ss.versus_game_team as vgt
						where vgt.game_id = vgtm.game_id
							and vgt.freq <> vgtm.freq
							and vgt.is_winner
					)
					then -1 -- lose
					else 0 -- draw
				end
			 end as result
			,vgtm.play_duration
			,vgtm.ship_mask
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
			,vgtm.first_out
			,vgtm.wasted_energy
			,vgtm.wasted_repel
			,vgtm.wasted_rocket
			,vgtm.wasted_thor
			,vgtm.wasted_burst
			,vgtm.wasted_decoy
			,vgtm.wasted_portal
			,vgtm.wasted_brick
			,vgtm.rating_change
			,vgtm.enemy_distance_sum
			,vgtm.enemy_distance_samples
			,vgtm.team_distance_sum
			,vgtm.team_distance_samples
		from ss.game as g
		inner join ss.versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
				and player_id = l_player_id
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
		order by g.time_played desc
		limit p_limit offset p_offset;
end;
$$;

alter function ss.get_player_versus_game_stats owner to ss_developer;

revoke all on function ss.get_player_versus_game_stats from public;

grant execute on function ss.get_player_versus_game_stats to ss_web_server;
