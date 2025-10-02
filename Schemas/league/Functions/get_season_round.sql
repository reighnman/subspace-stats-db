create or replace function league.get_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
)
returns table(
	 round_name league.season_round.round_name%type
	,round_description league.season_round.round_description%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_round(2, 1);
*/

select
	 sr.round_name
	,sr.round_description
from league.season_round as sr
where sr.season_id = p_season_id
	and sr.round_number = p_round_number;

$$;

alter function league.get_season_round owner to ss_developer;

revoke all on function league.get_season_round from public;

grant execute on function league.get_season_round to ss_web_server;
