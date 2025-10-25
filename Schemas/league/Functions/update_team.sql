create or replace function league.update_team(
	 p_team_id league.team.team_id%type
	,p_team_name league.team.team_name%type
	,p_banner_small league.team.banner_small%type
	,p_banner_large league.team.banner_large%type
	,p_franchise_id league.team.franchise_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.team
set  team_name = p_team_name
	,banner_small = p_banner_small
	,banner_large = p_banner_large
	,franchise_id = p_franchise_id
where team_id = p_team_id;

$$;

alter function league.update_team owner to ss_developer;

revoke all on function league.update_team from public;

grant execute on function league.update_team to ss_web_server;
