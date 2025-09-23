create or replace function league.insert_league(
	 p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
)
returns league.league.league_id%type
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
Usage:
select * from league.insert_league('SVS Pro League', 12);
select * from league.insert_league('SVS Intermediate League', 12);
select * from league.insert_league('SVS Amateur League', 12);
select * from league.insert_league('SVS United League', 12);
select * from league.insert_league('SVS Draft League', 12);
select * from league.insert_league('Test 2v2 league', 2);

select * from league.league;
*/

insert into league.league(
	 league_name
	,game_type_id
)
values(
	 p_league_name
	,p_game_type_id
)
returning
	 league_id;

$$;

alter function league.insert_league owner to ss_developer;

revoke all on function league.insert_league from public;

grant execute on function league.insert_league to ss_web_server;