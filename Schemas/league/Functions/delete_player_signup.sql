create or replace function league.delete_player_signup(
	 p_player_name ss.player.player_name%type
	,p_season_id league.roster.season_id%type
)
returns void
language sql
as
$$

/*
*/

delete from league.roster as r
where r.season_id = p_season_id
	and r.player_id = (
		select p.player_id
		from ss.player as p
		where p.player_name = p_player_name
	)
	and team_id is null; -- not on a team

$$;

alter function league.delete_player_signup owner to ss_developer;

revoke all on function league.delete_player_signup from public;

grant execute on function league.delete_player_signup to ss_web_server;
