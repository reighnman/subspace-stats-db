create or replace function league.update_season_end_date(
	 p_season_id league.season.season_id%type
	,p_end_date league.season.end_date%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Updates a season's end date.
This can be used to end a season or reopen a previously ended season.
*/

update league.season
set end_date = p_end_date
where season_id = p_season_id;

$$;

alter function league.update_season_end_date owner to ss_developer;

revoke all on function league.update_season_end_date from public;

grant execute on function league.update_season_end_date to ss_web_server;
