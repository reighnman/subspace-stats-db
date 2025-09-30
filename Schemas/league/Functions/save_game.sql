create or replace function league.save_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_game_json jsonb
)
returns game.game_id%type
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Saves a league game.
*/

declare
	l_game_id ss.game.game_id%type;
begin
	-- Save the game data and store resulting game_id in the season_game record.
	update league.season_game as sg
	set game_id = ss.save_game(p_game_json)
		,game_status_id = 3 -- Complete
	where sg.season_game_id = p_season_game_id
	returning game_id
	into l_game_id;

	-- Update season_game_team with the results for each participating team.
	if exists(
		select *
		from ss.game as g
		inner join ss.game_type as gt
			on g.game_type_id = gt.game_type_id
		where g.game_id = l_game_id
			and gt.game_mode_id = 2 -- Team Versus
	) then
		-- Team Versus
		update league.season_game_team as sgt
		set  is_winner = dt.is_winner
			,score = dt.score
		from(
			select
				 vgt.freq
				,vgt.is_winner
				,vgt.score
			from ss.versus_game_team as vgt
			where vgt.game_id = l_game_id
		) as dt
		where sgt.season_game_id = p_season_game_id
			and sgt.freq = dt.freq;
	end if;

	-- Refresh team stats (wins, losses, draws) for all the teams that particpated.
	perform league.refresh_team_stats(sgt.team_id)
	from league.season_game_team as sgt
	where sgt.season_game_id = p_season_game_id;

	return l_game_id;
end;

$$;

alter function league.save_game owner to ss_developer;

revoke all on function league.save_game from public;

grant execute on function league.save_game to ss_zone_server;
