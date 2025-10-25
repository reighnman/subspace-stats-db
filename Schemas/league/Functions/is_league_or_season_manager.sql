create or replace function league.is_league_or_season_manager(
	 p_user_id text
	,p_season_id league.season.season_id%type
)
returns boolean
language sql
security definer
set search_path = league, pg_temp
as
$$

select
	exists(
		select *
		from league.season_user_role as sur
		where sur.user_id = p_user_id
			and sur.season_id = p_season_id
			and sur.season_role_id = 1 -- Manager
	)
	or exists(
		select *
		from league.season as s
		inner join league.league_user_role as lur
			on s.league_id = lur.league_id
		where s.season_id = p_season_id
			and lur.user_id = p_user_id
			and lur.league_role_id = 1 -- Manager
	);

$$;

alter function league.is_league_or_season_manager owner to ss_developer;

revoke all on function league.is_league_or_season_manager from public;

grant execute on function league.is_league_or_season_manager to ss_web_server;
