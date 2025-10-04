create or replace function league.get_franchises()
returns table(
	 franchise_id league.franchise.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets all franchises.
For choosing a franchise when creating or editing a team.

Usage:
select * from league.get_franchises();
*/

select
	 franchise_id
	,franchise_name
from league.franchise
order by franchise_name;

$$;

alter function league.get_franchises owner to ss_developer;

revoke all on function league.get_franchises from public;

grant execute on function league.get_franchises to ss_web_server;
