create or replace function league.get_season_rounds(
	p_season_id league.season.season_id%type
)
returns table(
	 round_number league.season_round.round_number%type
	,round_name league.season_round.round_name%type
	,round_description league.season_round.round_description%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_rounds(2);
*/

select
	 sr.round_number
	,sr.round_name
	,sr.round_description
from league.season_round as sr
where sr.season_id = p_season_id
order by sr.round_number;

$$;

alter function league.get_season_rounds owner to ss_developer;

revoke all on function league.get_season_rounds from public;

grant execute on function league.get_season_rounds to ss_web_server;
