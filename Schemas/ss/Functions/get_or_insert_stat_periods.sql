create or replace function ss.get_or_insert_stat_periods(
	 p_game_type_id game_type.game_type_id%type
	,p_as_of timestamptz
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,stat_tracking_id stat_tracking.stat_tracking_id%type
)
language sql
as
$$

/*
Usage:
select * from get_or_insert_stat_periods(4, current_timestamp);

select * from stat_period;
*/

with cte_all_periods as(
	select
		 st.stat_tracking_id
		,st.stat_period_type_id
		,sp.stat_period_id
	from stat_tracking as st
	left outer join stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
			and sp.period_range @> p_as_of
	where st.game_type_id = p_game_type_id
		and (st.is_auto_generate_period = true or sp.stat_period_id is not null)
)
,cte_insert_stat_period as(
	insert into stat_period(
		 stat_tracking_id
		,period_range
	)
	select
		 cap.stat_tracking_id
		,case cap.stat_period_type_id
			when 0 then( -- Forever
				select tstzrange(null, null)
			)
			when 1 then( -- Monthly
				select tstzrange(dt.start, dt.start + '1 month'::interval, '[)')
				from(
					select date_trunc('month', p_as_of) as start
				) as dt
			)
		 end as period_range
	from cte_all_periods as cap
	where cap.stat_period_id is null -- any that are null must have is_auto_generate_period = true
	returning
		 stat_period_id
		,stat_tracking_id
)
select
	 cap.stat_period_id
	,cap.stat_tracking_id
from cte_all_periods as cap
where cap.stat_period_id is not null
union
select
	 cisp.stat_period_id
	,cisp.stat_tracking_id
from cte_insert_stat_period as cisp;

$$;
