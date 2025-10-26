create or replace function league.get_season_players(
	p_season_id league.season.season_id%type
)
returns table(
	 player_id ss.player.player_id%type
	,player_name ss.player.player_name%type
	,signup_timestamp league.roster.signup_timestamp%type
	,team_id league.roster.team_id%type
	,enroll_timestamp league.roster.enroll_timestamp%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_players(2);
*/

select
	 r.player_id
	,p.player_name
	,r.signup_timestamp
	,r.team_id
	,r.enroll_timestamp
	,r.is_captain
	,r.is_suspended
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = p_season_id
order by p.player_name;

$$;

alter function league.get_season_players owner to ss_developer;

revoke all on function league.get_season_players from public;

grant execute on function league.get_season_players to ss_web_server;
