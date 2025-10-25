create or replace function league.insert_season_user_role(
	 p_season_id league.season.season_id%type
	,p_user_id league.season_user_role.user_id%type
	,p_season_role_id league.season_user_role.season_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a record into the league.season_user_role table.
*/

insert into league.season_user_role(
	 season_id
	,user_id
	,season_role_id
)
values(
	 p_season_id
	,p_user_id
	,p_season_role_id
);

$$;

alter function league.insert_season_user_role owner to ss_developer;

revoke all on function league.insert_season_user_role from public;

grant execute on function league.insert_season_user_role to ss_web_server;
