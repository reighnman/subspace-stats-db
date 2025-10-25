create or replace function league.delete_season(
	p_season_id league.season.season_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.delete_season(123);

select * from league.season;
*/

delete from league.season where season_id = p_season_id;

$$;

alter function league.delete_season owner to ss_developer;

revoke all on function league.delete_season from public;

grant execute on function league.delete_season to ss_web_server;
