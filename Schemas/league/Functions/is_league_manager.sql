create or replace function league.is_league_manager(
	 p_user_id text
	,p_league_id league.league.league_id%type
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
		from league.league_user_role
		where user_id = p_user_id
			and league_id = p_league_id
			and league_role_id = 1 -- Manager
	);

$$;

alter function league.is_league_manager owner to ss_developer;

revoke all on function league.is_league_manager from public;

grant execute on function league.is_league_manager to ss_web_server;
