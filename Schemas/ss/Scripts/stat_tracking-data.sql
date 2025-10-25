--select * from ss.stat_tracking

merge into ss.stat_tracking as st
using(
	select
		 v.stat_tracking_id
		,v.game_type_id
		,v.stat_period_type_id
		,v.is_auto_generate_period
		,v.is_rating_enabled
		,v.initial_rating
		,v.minimum_rating
		,case when exists(
				select *
				from ss.stat_period as sp
				where sp.stat_tracking_id = v.stat_tracking_id
			)
			then true
			else false
		 end as IsInUse
	from(
		values
			 (1, 4, 1, true, true, 500, 100) -- 4v4 Monthly
			,(2, 2, 1, true, true, 500, 100) -- 2v2 Monthly
			,(3, 2, 0, true, false, null, null) -- 2v2 Forever
			,(4, 4, 0, true, false, null, null) -- 4v4 Forever
			,(5, 1, 0, true, false, null, null) -- 1v1 Forever
			,(6, 3, 0, true, false, null, null) -- 3v3 Forever
			,(7, 3, 1, true, true, 500, 100) -- 3v3 Monthly
	) as v(stat_tracking_id, game_type_id, stat_period_type_id, is_auto_generate_period, is_rating_enabled, initial_rating, minimum_rating)
) as dv
	on st.stat_tracking_id = dv.stat_tracking_id
when matched and dv.IsInUse = false then
	update set
		 game_type_id = dv.game_type_id
		,stat_period_type_id = dv.stat_period_type_id
		,is_auto_generate_period = dv.is_auto_generate_period
		,is_rating_enabled = dv.is_rating_enabled
		,initial_rating = dv.initial_rating
		,minimum_rating = dv.minimum_rating
when not matched then
	insert(
		 stat_tracking_id
		,game_type_id
		,stat_period_type_id
		,is_auto_generate_period
		,is_rating_enabled
		,initial_rating
		,minimum_rating
	)
	values(
		 dv.stat_tracking_id
		,dv.game_type_id
		,dv.stat_period_type_id
		,dv.is_auto_generate_period
		,dv.is_rating_enabled
		,dv.initial_rating
		,dv.minimum_rating
	);

-- Update the identity column value.
select setval(pg_get_serial_sequence('ss.stat_tracking', 'stat_tracking_id'), dt.next_stat_tracking_id)
from(
	select max(stat_tracking_id)+1 as next_stat_tracking_id from ss.stat_tracking
) as dt;
