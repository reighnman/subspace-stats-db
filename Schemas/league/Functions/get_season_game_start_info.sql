create or replace function league.get_season_game_start_info(
	p_season_game_id league.season_game.season_game_id%type
)
returns json
language sql
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
select league.get_season_game_start_info(23);
*/

select to_json(dt.*)
from(
	select
		 sg.season_game_id
		,l.game_type_id
		,l.league_id
		,l.league_name
		,s.season_id
		,s.season_name
		,sg.round_number
		,sr.round_name
		,sg.scheduled_timestamp
		,(	select json_object_agg(dt2.freq, json_build_object('team_id', dt2.team_id, 'team_name', dt2.team_name, 'roster', dt2.roster))
			from(
				select
					 sgt.freq
					,sgt.team_id
					,t.team_name
					,(	select json_object_agg(p.player_name, r.is_captain)
						from league.roster as r
						inner join ss.player as p
							on r.player_id = p.player_id
						where r.team_id = sgt.team_id
							and r.is_suspended = false
					 ) as roster
				from league.season_game_team as sgt
				inner join league.team as t
					on sgt.team_id = t.team_id
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt2
		 ) as teams
	from league.season_game as sg
	inner join league.season as s
		on sg.season_id = s.season_id
	inner join league.league as l
		on s.league_id = l.league_id
	left outer join league.season_round as sr
		on sg.season_id = sr.season_id
			and sg.round_number = sr.round_number
	where sg.season_game_id = p_season_game_id
) as dt;

$$;

alter function league.get_season_game_start_info owner to ss_developer;

revoke all on function league.get_season_game_start_info from public;

grant execute on function league.get_season_game_start_info to ss_zone_server;
