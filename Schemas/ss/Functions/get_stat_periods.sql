create or replace function ss.get_stat_periods(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,period_range ss.stat_period.period_range%type
	,stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,period_extra_name character varying
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the available stats periods for a specified game type and period type.

Parameters:
p_game_type_id - The game type to get stat periods for.
p_stat_period_type_id - The type of stat period to get.
p_limit - The maximum # of stat periods to return.
p_offset - The offset of the stat periods to return.

Usage:
select * from ss.get_stat_periods(2, 1, 12, 0) -- 2v2pub, monthly, limit 12 (1 year), offset 0
select * from ss.get_stat_periods(2, 0, 1, 0) -- 2v2pub, forever, limit 1, offset 0
*/

select
	 sp.stat_period_id
	,sp.period_range
	,st.stat_period_type_id
	,ss.get_stat_period_extra_name(sp.stat_period_id) as period_extra_name
from ss.stat_tracking as st
inner join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.game_type_id = p_game_type_id
	and st.stat_period_type_id = coalesce(p_stat_period_type_id, st.stat_period_type_id)
	and (p_stat_period_type_id is not null or st.stat_period_type_id <> 0) -- don't send 'forever' stat periods when no period type is passed in
order by sp.period_range desc
limit p_limit offset p_offset;

$$;

alter function ss.get_stat_periods owner to ss_developer;

revoke all on function ss.get_stat_periods from public;

grant execute on function ss.get_stat_periods to ss_web_server;
