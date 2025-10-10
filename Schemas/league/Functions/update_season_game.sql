create or replace function league.update_season_game(
	 p_game_json jsonb
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.season_game_team where season_game_id = 134;
select * from league.season_game where season_game_id = 134;
--delete from league.season_game;
--delete from league.season_game_team;
*/

with cte_game as(
	select
		 season_game_id
		,round_number
		,scheduled_timestamp
		,game_status_id
		,teams
	from jsonb_to_record(p_game_json) as(
		 season_game_id bigint
		,round_number int
		,scheduled_timestamp timestamptz
		,game_status_id bigint
		,teams jsonb
	)
)
,cte_team as(
	select
		 team_id
		,freq
		,is_winner
		,score
	from cte_game as cg
	cross join jsonb_to_recordset(cg.teams) as(
		 team_id bigint
		,freq smallint
		,is_winner boolean
		,score integer
	)
)
,cte_update_season_game as(
	update league.season_game as sg
	set  round_number = cg.round_number
		,scheduled_timestamp = cg.scheduled_timestamp
		,game_status_id = cg.game_status_id
	from cte_game as cg
	where sg.season_game_id = cg.season_game_id
)
,cte_delete_season_game_team as(
	delete from league.season_game_team as sgt
	where sgt.season_game_id = (select season_game_id from cte_game)
		and sgt.team_id not in(
			select team_id
			from cte_team
		)
)
,cte_update_season_game_team as(
	update league.season_game_team as sgt
	set  freq = ct.freq
		,is_winner = ct.is_winner
		,score = ct.score
	from cte_team as ct
	where sgt.season_game_id = (select season_game_id from cte_game)
		and sgt.team_id = ct.team_id
)
insert into league.season_game_team(
	 season_game_id
	,team_id
	,freq
	,is_winner
	,score
)
select
	 cg.season_game_id
	,ct.team_id
	,ct.freq
	,ct.is_winner
	,ct.score
from cte_game as cg
cross join cte_team as ct
where not exists(
		select *
		from league.season_game_team as sgt
		where sgt.season_game_id = cg.season_game_id
			and sgt.team_id = ct.team_id
	);
$$;

alter function league.update_season_game owner to ss_developer;

revoke all on function league.update_season_game from public;

grant execute on function league.update_season_game to ss_web_server;
