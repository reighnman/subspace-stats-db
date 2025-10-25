create or replace function league.get_franchise(
	p_franchise_id league.franchise.franchise_id%type
)
returns table(
	franchise_name league.franchise.franchise_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_franchise(3);
*/

select f.franchise_name
from league.franchise as f
where f.franchise_id = p_franchise_id;

$$;

alter function league.get_franchise owner to ss_developer;

revoke all on function league.get_franchise from public;

grant execute on function league.get_franchise to ss_web_server;
