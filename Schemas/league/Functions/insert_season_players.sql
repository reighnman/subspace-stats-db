create or replace function league.insert_season_players(
	 p_season_id league.season.season_id%type
	,p_player_names character varying(20)[]
	,p_team_id league.team.team_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Signs up players for a season. Optionally, with a team specified.

This is only an insert. It is not an upsert.
If a player is already signed up, that record is not updated (even if team differs).

Usage:
select league.insert_season_players(2, ARRAY['foo', 'bar'], null);
*/

with cte_players as(
	select ss.get_or_insert_player(dt.player_name) as player_id
	from(
		select distinct t.player_name collate ss.case_insensitive
		from unnest(p_player_names) as t(player_name)
	) as dt
)
insert into league.roster(
	 season_id
	,player_id
	,team_id
	,enroll_timestamp
)
select
	 p_season_id
	,c.player_id
	,p_team_id
	,case when p_team_id is null then null else current_timestamp end as enroll_timestamp
from cte_players as c
where not exists(
		select *
		from league.roster as r
		where r.season_id = p_season_id
			and r.player_id = c.player_id
	);

$$;

alter function league.insert_season_players owner to ss_developer;

revoke all on function league.insert_season_players from public;

grant execute on function league.insert_season_players to ss_web_server;
