create or replace function league.update_season(
	 p_season_id league.season.season_id%type
	,p_season_name league.season.season_name%type
	,p_start_date league.season.start_date%type
	,p_end_date league.season.end_date%type
	,p_stat_period_id league.season.stat_period_id%type
)
returns void
language sql
as
$$

/*
select league.update_season(s.season_id, s.season_name, CURRENT_DATE, null, null)
from league.season as s
where s.season_id = 2;

select * from league.season;
*/

update league.season
set  season_name = coalesce(p_season_name, season_name)
	,start_date = p_start_date
	,end_date = p_end_date
	,stat_period_id = p_stat_period_id
where season_id = p_season_id;

$$;

alter function league.update_season owner to ss_developer;

revoke all on function league.update_season from public;

grant execute on function league.update_season to ss_web_server;
