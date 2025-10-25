create or replace function league.insert_team(
	 p_team_name league.team.team_name%type
	,p_season_id league.team.season_id%type
	,p_banner_small league.team.banner_small%type
	,p_banner_large league.team.banner_large%type
	,p_franchise_id league.team.franchise_id%type
)
returns league.team.team_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.insert_team('ONE', 2, null, null);
select * from league.insert_team('Team 2', 2, null, null);
select * from league.insert_team('Team Three', 2, null, null);
select * from league.insert_team('4our', 2, null, null);

select * from league.team;
*/

insert into league.team(
	 team_name
	,season_id
	,banner_small
	,banner_large
	,franchise_id
)
values(
	 p_team_name
	,p_season_id
	,p_banner_small
	,p_banner_large
	,p_franchise_id
)
returning
	team_id;
	
$$;

alter function league.insert_team owner to ss_developer;

revoke all on function league.insert_team from public;

grant execute on function league.insert_team to ss_web_server;
