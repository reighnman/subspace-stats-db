create or replace function league.delete_league(
	p_league_id league.league.league_id%type
)
returns void
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
select league.delete_league()

select * from league.league
*/

delete from league.league where league_id = p_league_id;

$$;

alter function league.delete_league owner to ss_developer;

revoke all on function league.delete_league from public;

grant execute on function league.delete_league to ss_web_server;
