create or replace function league.refresh_season_team_stats(
	p_season_id league.season.season_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Refreshes the team stats (wins/losses/draws) of all teams in a season.
This is useful if a match is added or edited as complete with manually entered scores, or if a previously completed match is deleted.
*/

select league.refresh_team_stats(t.team_id)
from league.team as t
where t.season_id = p_season_id;

$$;

alter function league.refresh_season_team_stats owner to ss_developer;

revoke all on function league.refresh_season_team_stats from public;

grant execute on function league.refresh_season_team_stats to ss_web_server;
