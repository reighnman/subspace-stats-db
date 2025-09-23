create or replace function league.refresh_team_stats(
	p_team_id league.team.team_id%type
)
returns void
language sql
as
$$

/*
Refreshes a team's stats (wins/losses/draws).
*/

update league.team as t
set  wins = dt2.wins
	,losses = dt2.losses
	,draws = dt2.draws
from(
	select
		 count(*) filter(where dt.win_lose_draw = 'W') as wins
		,count(*) filter(where dt.win_lose_draw = 'L') as losses
		,count(*) filter(where dt.win_lose_draw = 'D') as draws
	from(
		select
			case 
				when sgt.is_winner then 'W'
				when exists(
						select *
						from league.season_game_team as sgt2
						where sgt2.season_game_id = sgt.season_game_id
							and sgt2.team_id <> p_team_id
							and sgt2.is_winner
					)
					then 'L'
				else 'D'
			 end win_lose_draw
		from league.season_game_team as sgt
		where team_id = p_team_id
	) as dt
) as dt2
where t.team_id = p_team_id;

$$;

alter function league.refresh_team_stats owner to ss_developer;

revoke all on function league.refresh_team_stats from public;

grant execute on function league.refresh_team_stats to ss_web_server;
grant execute on function league.refresh_team_stats to ss_zone_server;
