create or replace function league.get_scheduled_games(
	 p_season_id league.season.season_id%type
)
returns table(
	 league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,season_game_id league.season_game.season_game_id%type
	,round_number league.season_round.round_number%type
	,round_name league.season_round.round_name%type
	,game_timestamp league.season_game.game_timestamp%type
	,teams text
	,game_status_id league.season_game.game_status_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_scheduled_games(null);
select * from league.get_scheduled_games(2);
--select * from league.season;
*/

select 
	 l.league_id
	,l.league_name
	,s.season_id
	,s.season_name
	,sg.season_game_id
	,sg.round_number
	,sr.round_name
	,sg.game_timestamp
	,(	select string_agg(t.team_name, ' vs ' order by freq)
		from league.season_game_team as sgt
		inner join league.team as t
			on sgt.team_id = t.team_id
		where sgt.season_game_id = sg.season_game_id
		group by sgt.season_game_id
	 ) as teams
	,sg.game_status_id
from league.season as s
inner join league.season_game as sg
	on s.season_id = sg.season_id
inner join league.league as l
	on s.league_id = l.league_id
left outer join league.season_round as sr
	on sg.season_id = sr.season_id
		and sg.round_number = sr.round_number
where s.season_id = coalesce(p_season_id, s.season_id)
	and s.start_date is not null -- season has started
	and s.end_date is null -- season is still ongoing
	and sg.game_status_id <> 3 -- not complete
order by
	 l.league_id
	,s.season_id
	,sg.game_timestamp
	,sg.game_status_id
	,sg.season_game_id;

$$;

alter function league.get_scheduled_games owner to ss_developer;

revoke all on function league.get_scheduled_games from public;

grant execute on function league.get_scheduled_games to ss_web_server;
grant execute on function league.get_scheduled_games to ss_zone_server;
