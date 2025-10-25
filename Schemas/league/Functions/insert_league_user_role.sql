create or replace function league.insert_league_user_role(
	 p_league_id league.league.league_id%type
	,p_user_id league.league_user_role.user_id%type
	,p_league_role_id league.league_user_role.league_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a record into the league.league_user_role table.
*/

insert into league.league_user_role(
	 league_id
	,user_id
	,league_role_id
)
values(
	 p_league_id
	,p_user_id
	,p_league_role_id
);

$$;

alter function league.insert_league_user_role owner to ss_developer;

revoke all on function league.insert_league_user_role from public;

grant execute on function league.insert_league_user_role to ss_web_server;
