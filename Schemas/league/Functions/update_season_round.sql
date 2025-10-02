create or replace function league.update_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
	,p_round_name league.season_round.round_name%type
	,p_round_description league.season_round.round_description%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.update_season_round(2, 1, 'Round One', null);
*/

update league.season_round
set
	 round_name = p_round_name
	,round_description = p_round_description
where season_id = p_season_id
	and round_number = p_round_number;

$$;

alter function league.update_season_round owner to ss_developer;

revoke all on function league.update_season_round from public;

grant execute on function league.update_season_round to ss_web_server;
