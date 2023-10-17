-- select * from game_type;

merge into game_type as gt
using(
	values
		 (1,'SVS - Duel (1v1)',true,false,false)
		,(2,'SVS - 2v2 public', false, true, false)
		,(3,'SVS - 3v3 public', false, true, false)
		,(4,'SVS - 4v4 public', false, true, false)
		,(5,'PowerBall - Traditional', false, false, true)
		,(6,'PowerBall - Proball', false, false, true)
		,(7,'PowerBall - Smallpub', false, false, true)
		,(8,'PowerBall - 3h', false, false, true)
		,(9,'PowerBall - small4tmpb', false, false, true)
		,(10,'PowerBall - minipub', false, false, true)
		,(11,'PowerBall - mediumpub', false, false, true)
		,(12,'SVS - 4v4 league', false, true, false)
		,(13,'SVS - Solo FFA - 1 player/team', true, false, false)
		,(14,'SVS - Team FFA - 2 players/team', false, true, false)
) as v(game_type_id, game_type_description, is_solo, is_team_versus, is_pb)
	on gt.game_type_id = v.game_type_id
when matched then
	update set
		 game_type_description = v.game_type_description
		,is_solo = v.is_solo
		,is_team_versus = v.is_team_versus
		,is_pb = v.is_pb
when not matched then
	insert(
		 game_type_id
		,game_type_description
		,is_solo
		,is_team_versus
		,is_pb
	)
	values(
		 v.game_type_id
		,v.game_type_description
		,v.is_solo
		,v.is_team_versus
		,v.is_pb
	);
