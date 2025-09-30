create or replace function league.get_team_games(
	 p_team_id league.team.team_id%type
)
returns table(
	 season_game_id league.season_game.season_game_id%type
	,round_number league.season_game.round_number%type
	,round_name league.season_round.round_name%type
	,game_timestamp timestamp with time zone
	,game_id league.season_game.game_id%type
	,teams text
	,win_lose_draw char(1)
	,scores text
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets league games for a team. This includes both, games that have been played and games that have not yet been played.
Games that have been played will have a game_id.

Usage:
select * from league.get_team_games(1);

select * from league.team;
select * from league.season_game_team where team_id = 1
select * from league.season_game
*/

select
	 sg.season_game_id
	,sg.round_number
	,sr.round_name
	,coalesce(upper(g.time_played), sg.scheduled_timestamp) as game_timestamp
	,sg.game_id
	,(	select string_agg(t.team_name, ' vs ' order by freq)
		from league.season_game_team as sgt2
		inner join league.team as t
			on sgt2.team_id = t.team_id
		where sgt2.season_game_id = sg.season_game_id
	 ) as teams -- TODO: maybe send back a json array of strings instead and let the UI decide how to format it
 	,case when exists(
		 	select *
			from ss.game as g
			inner join ss.game_type as gt
				on g.game_type_id = gt.game_type_id
			where g.game_id = sg.game_id
				and gt.game_mode_id = 2 -- Team Versus
		)
		then( -- Team Versus
			case when exists(
					select *
					from ss.versus_game_team as vgt
					where vgt.game_id = sg.game_id
						and vgt.freq = sgt.freq
						and vgt.is_winner
				)
				then 'W' -- win
				else case when exists(
						select *
						from ss.versus_game_team as vgt
						where vgt.game_id = sg.game_id
							and vgt.freq <> sgt.freq
							and vgt.is_winner
					)
					then 'L' -- lose
					else 'D' -- draw
				end
			end
		)
	 end as win_lose_draw
	,(	select string_agg(cast(sgt2.score as text), ' - ' order by freq)
		from league.season_game_team as sgt2
		where sgt2.season_game_id = sgt.season_game_id
	 ) as scores
from league.season_game_team as sgt
inner join league.season_game as sg
	on sgt.season_game_id = sg.season_game_id
left outer join league.season_round as sr
	on sg.season_id = sr.season_id
		and sg.round_number = sr.round_number
left outer join ss.game as g
	on sg.game_id = g.game_id
where sgt.team_id = p_team_id
order by sg.scheduled_timestamp desc nulls first;

$$;

alter function league.get_team_games owner to ss_developer;

revoke all on function league.get_team_games from public;

grant execute on function league.get_team_games to ss_web_server;
grant execute on function league.get_team_games to ss_zone_server;
