create or replace function league.get_team_roster(
	p_team_id league.team.team_id%type
)
returns table(
	 player_id league.roster.player_id%type
	,player_name ss.player.player_name%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
	,enroll_timestamp league.roster.enroll_timestamp%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_team_roster(1);
select * from league.get_team_roster(2);
select * from league.get_team_roster(3);
select * from league.get_team_roster(4);
*/

select
	 r.player_id
	,p.player_name
	,r.is_captain
	,r.is_suspended
	,r.enroll_timestamp
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.team_id = p_team_id
order by
	 r.is_captain desc
	,p.player_name;

$$;

alter function league.get_team_roster owner to ss_developer;

revoke all on function league.get_team_roster from public;

grant execute on function league.get_team_roster to ss_web_server;
grant execute on function league.get_team_roster to ss_zone_server;
