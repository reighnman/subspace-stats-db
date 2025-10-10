create or replace function league.get_season_game(
	p_season_game_id league.season_game.season_game_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets details about a season's game.

Parameters:
p_season_game_id - ID of the game to get info about.

Returns: 
json containing information about the game.
This includes the teams that in the match and their rosters.

Example:
{
  "game_type_id": 15,
  "game_mode_id": 2,
  "league_name": "Test 2v2 league",
  "season_name": "2v2 - Season 1",
  "round_number": 1,
  "scheduled_timestamp": null,
  "teams": [
    {
      "freq": 10,
      "team_id": 1,
      "team_name": "ONE",
      "roster": {
        "foo": false,
        "bar": false
      }
    },
    {
      "freq": 20,
      "team_id": 2,
      "team_name": "Team 2",
      "roster": {
        "G": false,
        "asdf": false
      }
    }
  ]
}

Usage:
select league.get_season_game(23);
*/

select to_json(dg.*)
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
	where sg.season_game_id = p_season_game_id
) as dg;

$$;

alter function league.get_season_game owner to ss_developer;

revoke all on function league.get_season_game from public;

grant execute on function league.get_season_game to ss_web_server;
