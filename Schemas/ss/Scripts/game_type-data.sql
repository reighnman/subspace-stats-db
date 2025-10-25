-- select * from game_type;

merge into game_type as gt
using(
	values
		 (1,'SVS Duel (1v1)', 1)
		,(2,'SVS 2v2 Public', 2)
		,(3,'SVS 3v3 Public', 2)
		,(4,'SVS 4v4 Public', 2)
		,(5,'PowerBall: Traditional', 3)
		,(6,'PowerBall: Proball', 3)
		,(7,'PowerBall: Smallpub', 3)
		,(8,'PowerBall: 3h', 3)
		,(9,'PowerBall: small4tmpb', 3)
		,(10,'PowerBall: minipub', 3)
		,(11,'PowerBall: mediumpub', 3)
		,(12,'SVS 4v4 League', 2)
		,(13,'SVS Solo FFA - 1 player/team', 2)
		,(14,'SVS Team FFA - 2 players/team', 2)
		,(15,'SVS 2v2 League', 2)
) as v(game_type_id, game_type_name, game_mode_id)
	on gt.game_type_id = v.game_type_id
when matched then
	update set
		 game_type_name = v.game_type_name
		,game_mode_id = v.game_mode_id
when not matched then
	insert(
		 game_type_id
		,game_type_name
		,game_mode_id
	)
	values(
		 v.game_type_id
		,v.game_type_name
		,v.game_mode_id
	);
