create or replace function league.get_season_details(
	p_season_id league.season.season_id%type
)
returns table(
	 season_name league.season.season_name%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,created_timestamp league.season.created_timestamp%type
	,start_date league.season.start_date%type
	,end_date league.season.end_date%type
	,stat_period_id league.season.stat_period_id%type
	,stat_period_range ss.stat_period.period_range%type
	,stat_game_type_id ss.stat_tracking.game_type_id%type
	,league_game_type_id league.league.game_type_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_details(2);
*/

select
	 s.season_name
	,l.league_id
	,l.league_name
	,s.created_timestamp
	,s.start_date
	,s.end_date
	,sp.stat_period_id
	,sp.period_range
	,st.game_type_id as stat_game_type_id
	,l.game_type_id as league_game_type_id
from league.season as s
inner join league.league as l
	on s.league_id = l.league_id
left outer join ss.stat_period as sp
	on s.stat_period_id = sp.stat_period_id
left outer join ss.stat_tracking as st
	on sp.stat_tracking_id = st.stat_tracking_id
where s.season_id = p_season_id;

$$;

alter function league.get_season_details owner to ss_developer;

revoke all on function league.get_season_details from public;

grant execute on function league.get_season_details to ss_web_server;
