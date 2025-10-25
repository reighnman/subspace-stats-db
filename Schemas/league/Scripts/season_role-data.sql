-- select * from league.season_role;

merge into league.season_role as lr
using(
	values
		(1, 'Manager')
) as v(season_role_id, season_role_name)
	on lr.season_role_id = v.season_role_id
when matched and v.season_role_name <> lr.season_role_name then
	update set
		season_role_name = v.season_role_name
when not matched then
	insert(
		 season_role_id
		,season_role_name
	)
	values(
		 v.season_role_id
		,v.season_role_name
	);
