create or replace function league.start_season(
	 p_season_id league.season.season_id%type
	,p_start_date league.season.start_date%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Starts a season.
This creates a new ss.stat_period, saving the resulting stat_period_id in the league.season table.
Also, the league.season.start_date is set.

Parameters:
p_season_id - The season to start.
p_start_date - The start date. null means use the current date.

Usage:
select league.start_season(2, '2025-09-13');
select league.start_season(3, '2020-01-24');
select league.start_season(4, '2025-09-20');

select * from league.season;
select * from ss.stat_tracking;
select * from ss.stat_period;
*/

declare
	l_stat_tracking_id ss.stat_tracking.stat_tracking_id%type;
	l_stat_period_id ss.stat_period.stat_period_id%type;
begin
	if p_start_date is null then
		p_start_date := current_date;
	end if;

	if not exists(
		select * from league.season where season_id = p_season_id
	) then
		raise exception 'Invalid season_id specified. (%)', p_season_id;
	end if;

	if exists(
		select * from league.season where season_id = p_season_id and (start_date is not null or stat_period_id is not null)
	) then
		raise exception 'The season was already started previously. (%)', p_season_id;
	end if;

	select st.stat_tracking_id
	into l_stat_tracking_id
	from league.season as s
	inner join league.league as l
		 on s.league_id = l.league_id
	inner join ss.stat_tracking as st
		on l.game_type_id = st.game_type_id
			and st.stat_period_type_id = 2 -- league season
	where s.season_id = p_season_id;

	if l_stat_tracking_id is null then
		insert into ss.stat_tracking(
			 game_type_id
			,stat_period_type_id
			,is_auto_generate_period
			,is_rating_enabled
			,initial_rating
			,minimum_rating
		)
		select
			 dt.game_type_id
			,2 -- league season
			,false
			,true
			,500
			,100
		from(
			select l.game_type_id
			from league.season as s
			inner join league.league as l
				on s.league_id = l.league_id
			where s.season_id = p_season_id
		) as dt
		returning stat_tracking_id
		into strict l_stat_tracking_id;
	end if;

	insert into ss.stat_period(
		 stat_tracking_id
		,period_range
	)
	values(
		 l_stat_tracking_id
		,tstzrange(p_start_date, null, '[)')
	)
	returning stat_period_id
	into strict l_stat_period_id;
	
	update league.season as s
	set start_date = p_start_date
		,stat_period_id = l_stat_period_id
	where s.season_id = p_season_id
		and s.start_date is null 
		and s.stat_period_id is null;
end;

$$;

alter function league.start_season owner to ss_developer;

revoke all on function league.start_season from public;

grant execute on function league.start_season to ss_zone_server;
