--select * from league.game_status

merge into league.game_status as gs
using(
	values
		 (1, 'Pending', 'Represents a newly created game that has not yet been played.')
		,(2, 'In Progress', 'Represents a game that is currently being played. A game will be set to this when it is announced.')
		,(3, 'Complete', 'Represents a game that has been completed. This includes if a game''s result is manually entered in (e.g. historic game data, or other games played outside of this system).')
) as v(game_status_id, game_status_name, game_status_description)
	on gs.game_status_id = v.game_status_id
when matched then
	update set
		 game_status_name = v.game_status_name
		,game_status_description = v.game_status_description
when not matched then
	insert(
		 game_status_id
		,game_status_name
		,game_status_description
	)
	values(
		 v.game_status_id
		,v.game_status_name
		,v.game_status_description
	);
