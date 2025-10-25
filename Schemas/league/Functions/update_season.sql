create or replace function league.update_season(
	 p_season_id league.season.season_id%type
	,p_season_name league.season.season_name%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.update_season(2, '2v2 Season 1')
select * from league.season;
*/

update league.season
set  season_name = p_season_name
where season_id = p_season_id;

$$;

alter function league.update_season owner to ss_developer;

revoke all on function league.update_season from public;

grant execute on function league.update_season to ss_web_server;
