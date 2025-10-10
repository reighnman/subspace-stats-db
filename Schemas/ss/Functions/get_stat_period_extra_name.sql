create or replace function ss.get_stat_period_extra_name(
	p_stat_period_id ss.stat_period.stat_period_id%type
)
returns character varying
language sql
as
$$

/*
select ss.get_stat_period_extra_name(38);
*/

select
	case when st.stat_period_type_id = 2 -- League Season
		then(
			select s.season_name
			from league.season as s
			where s.stat_period_id = sp.stat_period_id
			limit 1
		)
		else null
	 end as extra_name
from ss.stat_period as sp
inner join ss.stat_tracking as st
	on sp.stat_tracking_id = st.stat_tracking_id
where sp.stat_period_id = p_stat_period_id;

$$;

alter function ss.get_stat_period_extra_name owner to ss_developer;

revoke all on function ss.get_stat_period_extra_name from public;

grant execute on function ss.get_stat_period_extra_name to ss_web_server;
grant execute on function ss.get_stat_period_extra_name to ss_zone_server;
