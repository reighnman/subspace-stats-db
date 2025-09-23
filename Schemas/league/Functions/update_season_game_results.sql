create or replace function league.update_season_game_results(
	 p_season_game_id league.season_game.season_game_id%type
	,p_results_json json
)
returns void
language sql
as
$$

/*
Updates a game's results.
The season_game's status is updated to 2 (Complete) and the associated season_game_team rows are updated with the results.

Parameters:
p_season_game_id - ID of the game to update.
p_manual_results_json - json representing the game's results in the format:
[
  {
    "team_id": 1,
	"is_winner": true,
	"score": 12
  },
  {
    "team_id": 2,
	"is_winner": false,
	"score": 8
  }
]
*/

with cte_update_season_game as(
	update league.season_game
	set game_status_id = 3
	where season_game_id = p_season_game_id
)
,cte_team_results as(
	select *
	from json_to_recordset(p_results_json) as tr(
		 team_id bigint
		,is_winner boolean
		,score integer
	)
)
update league.season_game_team as sgt
set  is_winner = c.is_winner
	,score = c.score
from cte_team_results as c
where sgt.season_game_id = p_season_game_id
	and sgt.team_id = c.team_id;

$$;

alter function league.update_season_game_results owner to ss_developer;

revoke all on function league.update_season_game_results from public;

grant execute on function league.update_season_game_results to ss_web_server;
