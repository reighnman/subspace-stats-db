create or replace function league.get_leagues()
returns table(
	 league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
	,game_type_description ss.game_type.game_type_description%type
)
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
select * from league.get_leagues();
*/

select
	 l.league_id
	,l.league_name
	,l.game_type_id
	,gt.game_type_description
from league.league as l
inner join ss.game_type as gt
	on l.game_type_id = gt.game_type_id;

$$;

alter function league.get_leagues owner to ss_developer;

revoke all on function league.get_leagues from public;

grant execute on function league.get_leagues to ss_web_server;
