create or replace function league.get_season_user_roles(
	 p_season_id league.season.season_id%type
)
returns table(
	 user_id league.season_user_role.user_id%type
	,season_role_id league.season_user_role.season_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_user_roles(2);
*/

select
	 user_id
	,season_role_id
from league.season_user_role
where season_id = p_season_id

$$;

alter function league.get_season_user_roles owner to ss_developer;

revoke all on function league.get_season_user_roles from public;

grant execute on function league.get_season_user_roles to ss_web_server;
