create or replace function league.insert_season(
	 p_season_name league.season.season_name%type
	,p_league_id league.season.league_id%type
)
returns league.season.season_id%type
language sql
as
$$

/*
Usage:
select * from league.insert_season('2v2 - Season 1', 13);

select * from league.season;
*/

insert into league.season(season_name, league_id)
values(p_season_name, p_league_id)
returning season_id;

$$;

alter function league.insert_season owner to ss_developer;

revoke all on function league.insert_season from public;

grant execute on function league.insert_season to ss_web_server;
