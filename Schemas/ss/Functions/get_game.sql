create or replace function ss.get_game(
	p_game_id game.game_id%type
)
returns json
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets details about a single game as json.
Note: json is used instead of jsonb since the attribute order matters for deserializing polymorphic types.

Parameters:
p_game_id - Id of the game to get data for.

Usage:
select ss.get_game(155);
*/

select to_json(dt.*)
from(
	select
		 g.game_id
		,g.game_type_id
		,zs.zone_server_name
		,a.arena_name
		,g.box_number
		,(lower(g.time_played) at time zone 'UTC') as start_time
		,(upper(g.time_played) at time zone 'UTC') as end_time
		,g.replay_path
		,l.lvl_file_name
		,l.lvl_checksum
		,(	select json_agg(edt.event_json)
		  	from(
				select
					case ge.game_event_type_id
						when 1 then( -- Versus - Assign slot
							select to_json(dt.*)
							from(
								select 
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,ase.freq
									,ase.slot_idx
									,p.player_name as player
								from versus_game_assign_slot_event as ase
								inner join player as p
									on ase.player_id = p.player_id
								where ase.game_event_id = ge.game_event_id
							) as dt
						)
						when 2 then( -- Versus - Player kill
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,p1.player_name as killed_player
									,p2.player_name as killer_player
									,ke.is_knockout
									,ke.is_team_kill
									,ke.x_coord
									,ke.y_coord
									,ke.killed_ship
									,ke.killer_ship
									,ke.score
									,ke.remaining_slots
									,(	select json_object_agg(p3.player_name, ged.damage)
										from game_event_damage as ged
										inner join player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
									,(	select json_object_agg(p4.player_name, ger.rating)
										from game_event_rating as ger
										inner join player as p4
											on ger.player_id = p4.player_id
										where ger.game_event_id = ge.game_event_id
									) as rating_changes
								from versus_game_kill_event as ke
								inner join player as p1
									on ke.killed_player_id = p1.player_id
								inner join player as p2
									on ke.killer_player_id = p2.player_id
								where ke.game_event_id = ge.game_event_id
							) as dt
						)
						when 3 then( -- Ship change
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,p.player_name as player
									,sce.ship
								from game_ship_change_event as sce
								inner join player as p
									on sce.player_id = p.player_id
								where sce.game_event_id = ge.game_event_id
							) as dt
						)
						when 4 then( -- Use item
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,p.player_name as player
									,uie.ship_item_id
									,(	select json_object_agg(p3.player_name, ged.damage)
										from game_event_damage as ged
										inner join player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
								from game_use_item_event as uie
								inner join player as p
									on uie.player_id = p.player_id
								where uie.game_event_id = ge.game_event_id
							) as dt
						)
						else null
					end as event_json
				from game_event as ge
				where ge.game_id = g.game_id
				order by ge.event_idx
			) as edt
		 ) as events
		,(	select json_agg(tdt)
		  	from(
				select
					 vgt.freq
					,vgt.is_winner
					,vgt.score
					,(	select json_agg(mdt)
						from(
							select
								 vgtm.slot_idx
								,vgtm.member_idx
								,p.player_name as player
								,s.squad_name as squad
								,vgtm.premade_group
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
							from versus_game_team_member as vgtm
							inner join player as p
								on vgtm.player_id = p.player_id
							left outer join squad as s
								on p.squad_id = s.squad_id
							where vgtm.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
							order by
								 vgtm.slot_idx
								,vgtm.member_idx
						) as mdt
					 ) as members
				from versus_game_team as vgt
				where gt.game_mode_id = 2 -- Team Versus
					and vgt.game_id = g.game_id
				order by vgt.freq
			) as tdt
		 ) as team_stats
	from game as g
	inner join game_type as gt
		on g.game_type_id = gt.game_type_id
	inner join zone_server as zs
		on g.zone_server_id = zs.zone_server_id
	inner join arena as a
		on g.arena_id = a.arena_id
	inner join lvl as l
		on g.lvl_id = l.lvl_id
	where g.game_id = p_game_id
) as dt;

$$;

revoke all on function ss.get_game(
	p_game_id game.game_id%type
) from public;

grant execute on function ss.get_game(
	p_game_id game.game_id%type
) to ss_web_server;
