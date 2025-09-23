-- select * from game_type;

merge into game_type as gt
using(
	values
		 (1,'SVS - Duel (1v1)',true,false,false, 1)
		,(2,'SVS - 2v2 public', false, true, false, 2)
		,(3,'SVS - 3v3 public', false, true, false, 2)
		,(4,'SVS - 4v4 public', false, true, false, 2)
		,(5,'PowerBall - Traditional', false, false, true, 3)
		,(6,'PowerBall - Proball', false, false, true, 3)
		,(7,'PowerBall - Smallpub', false, false, true, 3)
		,(8,'PowerBall - 3h', false, false, true, 3)
		,(9,'PowerBall - small4tmpb', false, false, true, 3)
		,(10,'PowerBall - minipub', false, false, true, 3)
		,(11,'PowerBall - mediumpub', false, false, true, 3)
		,(12,'SVS - 4v4 league', false, true, false, 2)
		,(13,'SVS - Solo FFA - 1 player/team', true, false, false, 2)
		,(14,'SVS - Team FFA - 2 players/team', false, true, false, 2)
		,(15,'SVS - 2v2 league', false, true, false, 2)
) as v(game_type_id, game_type_description, is_solo, is_team_versus, is_pb, game_mode_id)
	on gt.game_type_id = v.game_type_id
when matched then
	update set
		 game_type_description = v.game_type_description
		,is_solo = v.is_solo
		,is_team_versus = v.is_team_versus
		,is_pb = v.is_pb
		,game_mode_id = v.game_mode_id
when not matched then
	insert(
		 game_type_id
		,game_type_description
		,is_solo
		,is_team_versus
		,is_pb
		,game_mode_id
	)
	values(
		 v.game_type_id
		,v.game_type_description
		,v.is_solo
		,v.is_team_versus
		,v.is_pb
		,v.game_mode_id
	);
