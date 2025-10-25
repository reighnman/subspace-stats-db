create or replace function league.delete_team(
	p_team_id league.team.team_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

delete from league.team
where team_id = p_team_id;

$$;

alter function league.delete_team owner to ss_developer;

revoke all on function league.delete_team from public;

grant execute on function league.delete_team to ss_web_server;
