create or replace function league.get_latest_seasons_with_standings(
	p_league_ids bigint[]
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.get_latest_seasons_with_standings(ARRAY[13, 12]);
select league.get_latest_seasons_with_standings(ARRAY[13133, 3112]);
*/

select json_agg(dt2)
from(
	select
		 dt.league_id
		,l.league_name
		,dt.season_id
		,s.season_name
		,(select coalesce(json_agg(get_standings), '[]'::json) from league.get_standings(dt.season_id)) as standings
	from(
		select
			 p.league_id
			,p.league_order
			,(	select s.season_id
				from league.season as s
				where s.league_id = p.league_id
					and s.start_date is not null
				order by start_date desc
				limit 1
			) as season_id
		from unnest(p_league_ids) with ordinality as p(league_id, league_order)
	) as dt
	inner join league.league as l
		on dt.league_id = l.league_id
	inner join league.season as s
		on dt.season_id = s.season_id
	order by league_order
) as dt2;

$$;

alter function league.get_latest_seasons_with_standings owner to ss_developer;

revoke all on function league.get_latest_seasons_with_standings from public;

grant execute on function league.get_latest_seasons_with_standings to ss_web_server;
