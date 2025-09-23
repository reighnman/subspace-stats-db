create or replace function league.insert_player_signup(
	 p_player_name ss.player.player_name%type
	,p_season_id league.roster.season_id%type
)
returns void
language sql
as
$$

/*
Usage:
select league.insert_player_signup('G', 2);
select league.insert_player_signup('asdf', 2);
select league.insert_player_signup('foo', 2);
select league.insert_player_signup('bar', 2);
select league.insert_player_signup('baz', 2);
select league.insert_player_signup('qux', 2);
select league.insert_player_signup('qwer', 2);
select league.insert_player_signup('zxcv', 2);

select * from league.roster;
select * from ss.player;
*/

insert into league.roster(
	 season_id
	,player_id
	,signup_timestamp
	,is_captain
)
select
	 p_season_id
	,dt.player_id
	,current_timestamp
	,false
from(
	select
		coalesce(
			(	select p.player_id
				from ss.player as p
				where p.player_name = p_player_name
			)
			,ss.get_or_upsert_player(p_player_name, null, null, null)
		) as player_id
) as dt
where not exists(
		select * 
		from league.roster as r
		where r.season_id = p_season_id
			and r.player_id = dt.player_id
	);

$$;

alter function league.insert_player_signup owner to ss_developer;

revoke all on function league.insert_player_signup from public;

grant execute on function league.insert_player_signup to ss_web_server;
grant execute on function league.insert_player_signup to ss_zone_server;
