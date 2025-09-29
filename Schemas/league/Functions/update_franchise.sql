create or replace function league.update_franchise(
	 p_franchise_id league.franchise.franchise_id%type
	,p_franchise_name league.franchise.franchise_name%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.franchise
set franchise_name = p_franchise_name
where franchise_id = p_franchise_id;

$$;

alter function league.update_franchise owner to ss_developer;

revoke all on function league.update_franchise from public;

grant execute on function league.update_franchise to ss_web_server;
