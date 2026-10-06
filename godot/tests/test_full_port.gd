extends SceneTree
var failures: Array = []
var checks := 0
var issues: Dictionary = {}
func check(value: bool,message: String):
	checks+=1
	if not value: failures.append(message)
func _init():
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/catalog.json"))
	check(catalog.fighter.size()==58,"58 fighters/forms")
	check(catalog.assist.size()==37,"37 assists")
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/naruto.json"))
	for e in catalog.fighter:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+e.id+".json"))
		check(d.id==e.id,e.id+" identity")
		check(not d.frames.is_empty(),e.id+" animation")
		check(d.frames.size()==d.collisions.size(),e.id+" collision count")
		for label in ["砍1","砍技1","砍技2","招1","招2","招3","必杀","上必杀","超必杀","跳砍","跳招","跳必杀","摔1","摔2","开场","胜利","失败","万解","万解W","万解S"]:
			if not d.labels.has(label): continue
			var w=BVNBattle.new(d,baseline)
			w.training=true
			w.fighters[0].qi=300
			w.fighters[1].pos=w.fighters[0].pos+Vector2(48,0)
			if label.begins_with("跳"): w.fighters[0].pos.y-=70
			w.fighters[0].play(label)
			for n in range(400): w.tick([{},{}])
			check(w.fighters[0].frame>=1 and w.fighters[0].frame<=w.fighters[0].data.frames.size(),e.id+" "+label+" timeline bounds")
			if not w.unsupported_events.is_empty(): issues[e.id+" "+label]=w.unsupported_events.keys()
			w.dispose()
	for e in catalog.assist:
		var w=BVNBattle.new(baseline,baseline)
		w.training=true
		w.assist_ids=[e.id,e.id]
		w.fighters[1].pos=w.fighters[0].pos+Vector2(-8,0)
		w.spawn_assist(0)
		check(w.projectiles.size()>0,e.id+" assist spawn")
		for n in range(350): w.tick([{},{}])
		if not w.unsupported_events.is_empty(): issues["assist "+e.id]=w.unsupported_events.keys()
		w.dispose()
	var file:=FileAccess.open("user://full-port-test-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"unsupported":issues},"\t"))
	print("FULL PORT CHECKS ",checks," FAILURES ",failures.size()," UNSUPPORTED SCENARIOS ",issues.size())
	for failure in failures: print("FAIL ",failure)
	for key in issues: print("GAP ",key,": ",issues[key])
	quit(1 if not failures.is_empty() or not issues.is_empty() else 0)
