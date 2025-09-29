create or replace function league.get_season_games(
	p_season_id league.season.season_id%type
)
returns table(
	 season_game_id league.season_game.season_game_id%type
	,round_number league.season_game.round_number%type
	,scheduled_timestamp league.season_game.scheduled_timestamp%type
	,game_id league.season_game.game_id%type
	,game_status_id league.season_game.game_status_id%type
	,team_ids bigint[]
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

*/

select
	 sg.season_game_id
	,round_number
	,scheduled_timestamp
	,game_id
	,game_status_id
	,(	select array_agg(sgt.team_id)
		from league.season_game_team as sgt
		where sgt.season_game_id = sg.season_game_id
	 ) as team_ids
from league.season_game as sg
where sg.season_id = p_season_id;

$$;

alter function league.get_season_games owner to ss_developer;

revoke all on function league.get_season_games from public;

grant execute on function league.get_season_games to ss_web_server;
