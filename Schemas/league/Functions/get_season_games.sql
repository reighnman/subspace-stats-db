create or replace function league.get_season_games(
	p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the games for a season.

Parameters:
p_season_id - ID of the season to get.

Returns: 
JSON representing the games in the season

Usage:
select * from league.get_season_games(2);
select * from league.get_season_games(4);
*/

select coalesce(json_agg(to_json(dg)))
from(
	select
		 sg.season_game_id
		,sg.season_id
		,sg.round_number
		,sg.scheduled_timestamp AT TIME ZONE 'UTC' as scheduled_timestamp
		,sg.game_id
		,sg.game_status_id
		,(	select json_agg(to_json(dt))
			from(
				select
					 sgt.team_id
					,sgt.freq
					,sgt.score
					,sgt.is_winner
				from league.season_game_team as sgt
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt
		) as teams
	from league.season_game as sg
	where sg.season_id = p_season_id
	order by
		 sg.scheduled_timestamp desc nulls first
		,sg.round_number desc
		,sg.season_game_id
) as dg

$$;

alter function league.get_season_games owner to ss_developer;

revoke all on function league.get_season_games from public;

grant execute on function league.get_season_games to ss_web_server;
