create or replace function league.get_completed_games(
	 p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.get_completed_games(2);
select league.get_completed_games(4);
*/

select json_agg(row_to_json(dg) order by dg.round_number desc, dg.game_timestamp desc, dg.season_game_id)
from(
	select
		 sg.season_game_id
		,sg.round_number
		,sr.round_name
		,(coalesce(upper(g.time_played), sg.game_timestamp) at time zone 'UTC') as game_timestamp
		,(	select json_agg(row_to_json(dt))
			from(
				select
					 sgt.team_id
					,t.team_name
					,sgt.freq
					,sgt.is_winner
					,sgt.score
				from league.season_game_team as sgt
				inner join league.team as t
					on sgt.team_id = t.team_id
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt
		 ) as teams
		,sg.game_id
	from league.season_game as sg
	left outer join league.season_round as sr
		on sg.season_id = sr.season_id
			and sg.round_number = sr.round_number
	left outer join ss.game as g
		on sg.game_id = g.game_id
	where sg.season_id = p_season_id
		and sg.game_status_id = 3 -- Complete
) as dg


$$;

alter function league.get_completed_games owner to ss_developer;

revoke all on function league.get_completed_games from public;

grant execute on function league.get_completed_games to ss_web_server;
