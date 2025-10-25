create or replace function league.undo_end_season(
	 p_season_id league.season.season_id%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

begin
	update ss.stat_period as sp
	set period_range = tstzrange(lower(sp.period_range), null, '[)')
	where sp.stat_period_id = (
			select s.stat_period_id
			from league.season as s
			where s.season_id = p_season_id
		);
	
	update league.season
	set end_date = null
	where season_id = p_season_id;
end;
$$;

alter function league.undo_end_season owner to ss_developer;

revoke all on function league.undo_end_season from public;

grant execute on function league.undo_end_season to ss_web_server;