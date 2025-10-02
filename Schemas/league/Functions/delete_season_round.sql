create or replace function league.delete_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.delete_season_round(2, 1);
*/

delete from league.season_round as sr
where sr.season_id = p_season_id
	and sr.round_number = p_round_number;

$$;

alter function league.delete_season_round owner to ss_developer;

revoke all on function league.delete_season_round from public;

grant execute on function league.delete_season_round to ss_web_server;
