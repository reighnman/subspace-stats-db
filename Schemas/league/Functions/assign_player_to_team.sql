create or replace function league.assign_player_to_team(
	 p_player_id league.roster.player_id%type
	,p_team_id league.roster.team_id%type
)
returns boolean
language plpgsql
as
$$

/*
Assigns a team to a player that is signed up for league.

Usage:
select * from league.assign_player_to_team(86,2);
select * from league.assign_player_to_team(89,2);
select * from league.assign_player_to_team(88,1);
select * from league.assign_player_to_team(87,1);
select * from league.assign_player_to_team(90,3);
select * from league.assign_player_to_team(94,4);
select * from league.assign_player_to_team(95,3);
select * from league.assign_player_to_team(96,4);

select * from league.roster;
select * from league.team;

select * 
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = 2
*/

declare
	l_season_id league.season.season_id%type;
	--l_old_team_id league.team.team_id%type;
begin
	select season_id
	into l_season_id
	from league.team as t
	where t.team_id = p_team_id;

	if l_season_id is null then
		raise exception 'Invalid team (%).', p_team_id;
	end if;

	update league.roster as r
	set team_id = p_team_id
		,enroll_timestamp = current_timestamp
	where r.season_id = l_season_id
		and r.player_id = p_player_id;

	-- TODO: add history (e.g. player trades)
	--insert into league.roster_history() -- track old team and new team?
	
	return FOUND;
end;
$$;

alter function league.assign_player_to_team owner to ss_developer;

revoke all on function league.assign_player_to_team from public;

grant execute on function league.assign_player_to_team to ss_web_server;
grant execute on function league.assign_player_to_team to ss_zone_server;