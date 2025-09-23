create or replace function league.insert_season_game(
	 p_season_id league.season_game.season_id%type
	,p_round_number league.season_game.round_number%type
	,p_scheduled_timestamp league.season_game.scheduled_timestamp%type
	,p_team_ids bigint[]
	,p_freq_start smallint = 10
	,p_freq_increment smallint = 10
)
returns league.season_game.season_game_id%type
language sql
as
$$

/*
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
		,scheduled_timestamp
		,game_status_id
	)
	values(
		 p_season_id
		,p_round_number
		,p_scheduled_timestamp
		,1 -- Pending
	)
	returning season_game_id
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
	)
	select
		 csg.season_game_id
		,tm.team_id
		,p_freq_start + ((tm.team_order - 1) * p_freq_increment)
	from cte_season_game as csg
	cross join unnest(p_team_ids) with ordinality as tm(team_id, team_order) 
)
select season_game_id 
from cte_season_game;

$$;

alter function league.insert_season_game owner to ss_developer;

revoke all on function league.insert_season_game from public;

grant execute on function league.insert_season_game to ss_web_server;
