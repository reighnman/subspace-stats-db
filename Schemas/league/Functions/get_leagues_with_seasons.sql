create or replace function league.get_leagues_with_seasons()
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the available leagues and their seasons.

Usage:
select league.get_leagues_with_seasons();
*/

select json_agg(row_to_json(dt2))
from(
	select
		 dt.league_id
		,dt.league_name
		,(	select json_agg(row_to_json(sdt))
			from(
				select
					 s.season_id
					,s.season_name
				from league.season as s
				where s.league_id = dt.league_id
				order by
					 s.start_date desc nulls last
					,s.season_name 
			) as sdt
		 ) as seasons
	from(
		select
			 l.league_id
			,l.league_name
			,(	select max(s2.start_date)
				from league.season as s2
				where s2.league_id = l.league_id
					and s2.start_date is not null
				limit 1
			) as latest_season_start_date
		from league.league as l
		where exists(
				select *
				from league.season as s
				where s.league_id = l.league_id
			)
	) as dt
	order by
		 dt.latest_season_start_date desc nulls last
		,dt.league_name
) as dt2

$$;

alter function league.get_leagues_with_seasons owner to ss_developer;

revoke all on function league.get_leagues_with_seasons from public;

grant execute on function league.get_leagues_with_seasons to ss_web_server;
