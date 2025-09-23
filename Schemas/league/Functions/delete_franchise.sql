create or replace function league.delete_franchise(
	p_franchise_id league.franchise.franchise_id%type
)
returns void
language sql
as
$$

/*
*/

delete from league.franchise
where franchise_id = p_franchise_id;

$$;

alter function league.delete_franchise owner to ss_developer;

revoke all on function league.delete_franchise from public;

grant execute on function league.delete_franchise to ss_web_server;
