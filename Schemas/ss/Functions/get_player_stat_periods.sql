create or replace function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,game_type_id game_type.game_type_id%type
	,stat_period_type_id stat_period_type.stat_period_type_id%type
	,period_range stat_period.period_range%type
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the stat periods that a player has participated in.

Parameters:
p_player_name - The name of the player to get data for.
p_period_cutoff - How far back in time to look for periods.

Usage:
select * from get_player_stat_periods('asdf', null);
select * from get_player_stat_periods('asdf', interval '1 months');
*/

declare
	l_start timestamptz;
begin
	l_start := current_timestamp - coalesce(p_period_cutoff, interval '1 year');

	return query
		select
			 sp.stat_period_id
			,st.game_type_id
			,st.stat_period_type_id
			,sp.period_range
		from player as p
		inner join player_versus_stats as pvs -- TODO: add support for other game types (solo, pb)
			on p.player_id = pvs.player_id
		inner join stat_period as sp
			on pvs.stat_period_id = sp.stat_period_id
		inner join stat_tracking as st
			on sp.stat_tracking_id = st.stat_tracking_id
		where p.player_name = p_player_name
			and lower(sp.period_range) >= l_start
			and st.stat_period_type_id <> 0 -- Not the 'Forever' period type
		order by
			 st.game_type_id
			,sp.period_range desc;
end;	
$$;

revoke all on function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) from public;

grant execute on function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) to ss_web_server;
