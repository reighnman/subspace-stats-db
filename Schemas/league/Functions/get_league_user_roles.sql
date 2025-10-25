create or replace function league.get_league_user_roles(
	 p_league_id league.league.league_id%type
)
returns table(
	 user_id league.league_user_role.user_id%type
	,league_role_id league.league_user_role.league_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_league_user_roles(13);
*/

select
	 user_id
	,league_role_id
from league.league_user_role
where league_id = p_league_id

$$;

alter function league.get_league_user_roles owner to ss_developer;

revoke all on function league.get_league_user_roles from public;

grant execute on function league.get_league_user_roles to ss_web_server;
