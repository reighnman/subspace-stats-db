create or replace function ss.get_or_insert_lifetime_stat_tracking(
	p_game_type_id ss.game_type.game_type_id%type
)
returns ss.stat_period.stat_period_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the lifetime stat tracking period for a game type.
If it does not yet exist yet, the ss.stat_tracking record and the ss.stat_period record will be inserted.

Usage:
select ss.get_or_insert_lifetime_stat_tracking(3);

select * 
from ss.stat_tracking as st
left outer join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.stat_period_type_id = 0;
*/

with cte_insert_stat_tracking as(
	insert into ss.stat_tracking(
		 game_type_id
		,stat_period_type_id
		,is_auto_generate_period
		,is_rating_enabled
		,initial_rating
		,minimum_rating
	)
	select
		 p_game_type_id
		,0 -- lifetime / forever
		,true
		,false
		,null
		,null
	where not exists(
			select *
			from ss.stat_tracking as st
			where st.game_type_id = p_game_type_id
				and st.stat_period_type_id = 0 -- lifetime / forever
		)
	returning stat_tracking_id
)
,cte_insert_stat_period as(
	insert into ss.stat_period(
		 stat_tracking_id
		,period_range
	)
	select
		 cist.stat_tracking_id
		,tstzrange(null, null) -- the lifetime / forever period is unbounded
	from cte_insert_stat_tracking as cist
	returning stat_period_id
)
select cisp.stat_period_id
from cte_insert_stat_period as cisp
union
select sp.stat_period_id
from ss.stat_tracking as st
inner join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.game_type_id = p_game_type_id
	and stat_period_type_id = 0; -- lifetime / forever

$$;

alter function ss.get_or_insert_lifetime_stat_tracking owner to ss_developer;

revoke all on function ss.get_or_insert_lifetime_stat_tracking from public;

grant execute on function ss.get_or_insert_lifetime_stat_tracking to ss_web_server;
