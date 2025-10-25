create or replace function league.insert_season_game(
	 p_season_id league.season_game.season_id%type
	,p_round_number league.season_game.round_number%type
	,p_game_timestamp league.season_game.game_timestamp%type
	,p_game_status_id league.season_game.game_status_id%type
	,p_team_json jsonb
)
returns league.season_game.season_game_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a season game.

team_json: json describing the season_game_team data

Example of inserting a new match (when p_game_status_id = 1)
[
	{
		"team_id" : 123,
		"freq" : 10,
	},
	{
		"team_id" : 456,
		"freq" : 20,
	}
]

Example of inserting an completed match (when p_game_status_id = 3):
[
	{
		"team_id" : 123,
		"freq" : 10,
		"is_winner" : true,
		"score" : 6
	},
	{
		"team_id" : 456,
		"freq" : 20,
		"is_winner" : false,
		"score" : 2
	}
]

Usage:
select * from league.insert_season_game(2, 2, '2025-08-28', '{3, 1}');
select * from league.insert_season_game(2, 2, '2025-08-28', '{2, 4}');

select * from league.season_game;
select * from league.team;

select * from league.team;
select * from league.season_game where season_game_id = 38;
select * from league.season_game_team where season_game_id = 38;

select * from league.delete_season_game(38);
*/

with cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_timestamp
		,game_status_id
	)
	values(
		 p_season_id
		,p_round_number
		,p_game_timestamp
		,p_game_status_id
	)
	returning season_game_id
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
		,is_winner
		,score
	)
	select
		 csg.season_game_id
		,t.team_id
		,t.freq
		,t.is_winner
		,t.score
	from cte_season_game as csg
	cross join jsonb_array_elements(p_team_json) as a
	cross join jsonb_to_record(a.value) as t(
		 team_id bigint
		,freq int
		,is_winner boolean
		,score int
	)
)
select season_game_id 
from cte_season_game;

$$;

alter function league.insert_season_game owner to ss_developer;

revoke all on function league.insert_season_game from public;

grant execute on function league.insert_season_game to ss_web_server;
