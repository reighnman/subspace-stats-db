create function league.copy_season(
	 p_season_id league.season.season_id%type
	,p_season_name league.season.season_name%type
	,p_include_players boolean
	,p_include_teams boolean
	,p_include_games boolean
	,p_include_rounds boolean
)
returns league.season.season_id%type
language sql
as
$$

/*
Parameters:
p_season_id - The existing season to copy from.
p_season_name - The name of the new season.
p_include_teams - Whether to copy teams.
p_include_players - Whether to copy players.
p_include_games - Whether to copy games (p_include_teams must must be true).

Usage:
select league.copy_season(2, 'my copy', true, true, true, true);
*/

with cte_season as(
	insert into league.season(
		 season_name
		,league_id
	)
	select
		 p_season_name
		,s.league_id
	from league.season as s
	where s.season_id = p_season_id
	returning season_id
)
,cte_team as(
	insert into league.team(
		 team_name
		,season_id
		,banner_small
		,banner_large
		,franchise_id
	)
	select
		 t.team_name
		,cs.season_id
		,t.banner_small
		,t.banner_large
		,t.franchise_id
	from league.team as t
	cross join cte_season as cs
	where t.season_id = p_season_id
		and p_include_teams
	returning
		 team_id
		,team_name
)
,cte_team_with_old as(
	select
		 ct.team_id
		,ct.team_name
		,t.team_id as old_team_id
	from cte_team as ct
	inner join league.team as t
		on ct.team_name = t.team_name
	where t.season_id = p_season_id
)
,cte_games as(
	select
		 sg.season_game_id as old_season_game_id
		,row_number() over(order by season_game_id) as game_idx -- for matching up when inserting related records (e.g. season_game_team)
	from league.season_game as sg
	where sg.season_id = p_season_id
		and p_include_games
		and p_include_teams -- can't insert games without teams also
)
,cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_status_id
	)
	select
		 cs.season_id
		,sg.round_number
		,1 -- Pending
	from cte_games as cg
	inner join league.season_game as sg
		on cg.old_season_game_id = sg.season_game_id
	cross join cte_season as cs
	returning season_game_id
)
,cte_season_game_with_idx as(
	select
		 season_game_id -- newly inserted id
		,row_number() over(order by season_game_id) as game_idx
	from cte_season_game
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
	)
	select
		 csg.season_game_id
		,ct.team_id
		,sgt.freq
	from cte_season_game_with_idx as csg
	inner join cte_games as cg
		on csg.game_idx = cg.game_idx
	inner join league.season_game_team as sgt
		on cg.old_season_game_id = sgt.season_game_id
	inner join cte_team_with_old as ct
		on sgt.team_id = ct.old_team_id
)
,cte_season_round as(
	insert into league.season_round(
		 season_id
		,round_number
		,round_name
		,round_description
	)
	select
		 cs.season_id
		,sr.round_number
		,sr.round_name
		,sr.round_description
	from league.season_round as sr
	cross join cte_season as cs
	where sr.season_id = p_season_id
		and p_include_rounds
)
,cte_roster as(
	insert into league.roster(
		 season_id
		,player_id
		,signup_timestamp
		,team_id
		,enroll_timestamp
		,is_captain
		,is_suspended
	)
	select
		 cs.season_id
		,r.player_id
		,r.signup_timestamp
		,ct.team_id
		,r.enroll_timestamp
		,r.is_captain
		,r.is_suspended
	from league.roster as r
	inner join cte_team_with_old as ct
		on r.team_id = ct.old_team_id
	cross join cte_season as cs
	where r.season_id = p_season_id
		and p_include_players
)
select cs.season_id
from cte_season as cs;

$$;
