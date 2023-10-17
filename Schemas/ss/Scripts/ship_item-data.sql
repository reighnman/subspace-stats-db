-- select * from ss.ship_item

merge into ss.ship_item as se
using(
	values
		 (1, 'Repel')
		,(2, 'Rocket')
		,(3, 'Thor')
		,(4, 'Burst')
		,(5, 'Decoy')
		,(6, 'Portal')
		,(7, 'Brick')
) as v(ship_item_id, ship_item_name)
	on se.ship_item_id = v.ship_item_id
when matched then
	update set
		 ship_item_id = v.ship_item_id
		,ship_item_name = v.ship_item_name
when not matched then
	insert(
		 ship_item_id
		,ship_item_name
	)
	values(
		 v.ship_item_id
		,v.ship_item_name
	);
