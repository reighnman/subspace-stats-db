create or replace function league.insert_season_games_for_round_with_2_teams(
	 p_season_id league.season.season_id%type
	,p_permutations boolean
)
returns table(
	season_game_id league.season_game.season_game_id%type
)
language sql
as
$$

/*
Usage:
select * from league.insert_season_games_for_round_with_2_teams(2, false);
select * from league.insert_season_games_for_round_with_2_teams(2, true);

-- delete from league.season_game_team;
-- delete from league.season_game;
select * from league.season_game;
select * from league.season_game_team;
*/

-- TODO: add a column to ss.game_type to tell how many teams play in a match, for now assuming 2

with cte_team as(
	select st.team_id
	from league.team as st
	where st.season_id = p_season_id
		and st.is_enabled = true -- excludes teams that have been eliminated
)
,cte_game_team as(
	select
		 row_number() over(order by t1.team_id, t2.team_id) as game_idx
		,t1.team_id as team1_id
		,t2.team_id as team2_id
	from cte_team as t1
	cross join cte_team as t2
	where t1.team_id <> t2.team_id -- teams don't play against themselves
		and (p_permutations = true -- permutations: order matters (T1 vs T2, T2 vs T1) - home and away games
			or t1.team_id < t2.team_id -- combinations: order does not matter (T1 vs T2)
		)
)
,cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_status_id
	)
	select
		 p_season_id
		,coalesce(
			 (	select max(round_number) + 1
				from league.season_game as sg
				where sg.season_id = p_season_id
			 )
			,1
		 ) as round_number
		,1 as game_status_id -- Pending
	from cte_game_team as cgt
	returning
		 season_game.season_game_id
)
,cte_season_game_with_idx as(
	select
		 csg.season_game_id
		,row_number() over(order by season_game_id) as game_idx
	from cte_season_game as csg
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
	)
	select
		 dt.season_game_id
		,dt.team_id
		,dt.team_id * 10
	from(
		select
			 csg.season_game_id
			,cgt.team1_id as team_id
		from cte_season_game_with_idx as csg
		inner join cte_game_team as cgt
			on csg.game_idx = cgt.game_idx
		union
		select
			 csg.season_game_id
			,cgt.team2_id as team_id
		from cte_season_game_with_idx as csg
		inner join cte_game_team as cgt
			on csg.game_idx = cgt.game_idx
	) as dt
)
select csg.season_game_id
from cte_season_game as csg;

$$;

alter function league.insert_season_games_for_round_with_2_teams owner to ss_developer;

revoke all on function league.insert_season_games_for_round_with_2_teams from public;

grant execute on function league.insert_season_games_for_round_with_2_teams to ss_web_server;
