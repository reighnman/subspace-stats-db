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
Gets the stat periods for a given game type and timestamp.
Stat periods that do not exist yet are inserted if it is configured in the stat_tracking table to auto generate.

Parameters:
p_game_type_id - The game type to get stat periods for.
p_as_of - The timestamp to get stat periods for.

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
		and (sp.stat_period_id is not null
			or (sp.stat_period_id is null and st.is_auto_generate_period = true)
		)
)
,cte_insert_stat_period as(
	insert into stat_period(
		 stat_tracking_id
		,period_range
	)
	select
		 dt2.stat_tracking_id
		,dt2.period_range
	from(
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
	) as dt2
	where dt2.period_range is not null -- only if we know how to generate a new range for the stat_period_type_id
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
