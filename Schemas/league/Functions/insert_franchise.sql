create or replace function league.insert_franchise(
	p_franchise_name league.franchise.franchise_name%type
)
returns league.franchise.franchise_id%type
language sql
as

$$

/*
Usage:
select * from league.insert_franchise('testing 123');

select * from league.franchise
*/

insert into league.franchise(franchise_name)
values(p_franchise_name)
returning franchise_id;

$$;

alter function league.insert_franchise owner to ss_developer;

revoke all on function league.insert_franchise from public;

grant execute on function league.insert_franchise to ss_web_server;
