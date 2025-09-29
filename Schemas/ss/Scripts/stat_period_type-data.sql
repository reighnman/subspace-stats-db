--select * from stat_period_type;

merge into stat_period_type as rpt
using(
	values
		 (0, 'Forever')
		,(1, 'Monthly')
		,(2, 'League Season')
) as v(stat_period_type_id, stat_period_type_name)
	on rpt.stat_period_type_id = v.stat_period_type_id
when matched then
	update set
		stat_period_type_name = v.stat_period_type_name
when not matched then
	insert(
		 stat_period_type_id
		,stat_period_type_name
	)
	values(
		 v.stat_period_type_id
		,v.stat_period_type_name
	);
