--select * from ss.game_mode;

merge into ss.game_mode as gm
using(
	values
		 (1, '1v1')
		,(2, 'Team Versus')
		,(3, 'PowerBall')
) as v(game_mode_id, game_mode_name)
	on gm.game_mode_id = v.game_mode_id
when matched then
	update set game_mode_name = v.game_mode_name
when not matched then
	insert(
		 game_mode_id
		,game_mode_name
	)
	values(
		 v.game_mode_id
		,v.game_mode_name
	);
