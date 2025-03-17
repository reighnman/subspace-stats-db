-- select * from game_event_type;

merge into game_event_type as et
using(
	values
		 (1, 'Versus - Assign slot')
		,(2, 'Versus - Player kill')
		,(3, 'Versus - Player ship change')
		,(4, 'Versus - Player use item')
		,(100, 'PowerBall - Goal')
		,(101, 'PowerBall - Steal')
		,(102, 'PowerBall - Save')
) as v(game_event_type_id, game_event_type_description)
	on et.game_event_type_id = v.game_event_type_id
when matched then
	update set
		 game_event_type_description = v.game_event_type_description
when not matched then
	insert(
		 game_event_type_id
		,game_event_type_description
	)
	values(
		 v.game_event_type_id
		,v.game_event_type_description
	);
