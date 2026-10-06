extends SceneTree

func _init():
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/catalog.json"))
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/ichigo.json"))
	var failures: Array = []
	var rounds := 0
	for entry in catalog.fighter:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+entry.id+".json"))
		var battle := BVNBattle.new(baseline,d)
		battle.time_limit=false
		var ai := BVNAI.new(battle.fighters[1],3,340)
		for n in range(900):
			battle.tick([{},ai.decide()])
			if battle.finished: break
			if not is_finite(battle.fighters[1].pos.y) or battle.fighters[1].pos.y< -2000:
				failures.append(entry.id+" invalid AI vertical motion");break
		if not battle.unsupported_events.is_empty(): failures.append(entry.id+" "+str(battle.unsupported_events))
		rounds+=1
		ai.dispose();battle.dispose()
	for level in range(1,7):
		var battle := BVNBattle.new(baseline,baseline)
		var ai := BVNAI.new(battle.fighters[1],level,341)
		for n in range(500): battle.tick([{},ai.decide()])
		if not battle.unsupported_events.is_empty(): failures.append("difficulty "+str(level)+" "+str(battle.unsupported_events))
		rounds+=1
		ai.dispose();battle.dispose()
	print("ORIGINAL AI SCENARIOS ",rounds," FAILURES ",failures.size())
	for message in failures: print("FAIL ",message)
	quit(1 if failures.size()>0 else 0)
