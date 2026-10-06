extends SceneTree
const Battle = preload("res://scripts/battle.gd")
const Fighter = preload("res://scripts/fighter.gd")
var roster: Array = []
var failures: Array = []
var checks := 0
func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
func make_battle(swap := false):
	return Battle.new(roster[1 if swap else 0],roster[0 if swap else 1])
func _initialize():
	for character in ["ichigo","naruto"]:
		roster.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+character+"/fighter.json")))
		var d: Dictionary = roster.back()
		check(d.frames.size() == d.collisions.size(),character+" collision count")
		check(d.unparsed_calls.is_empty(),character+" unparsed import calls")
		for frame in d.frames:
			if frame != null: check(FileAccess.file_exists("res://assets/"+character+"/"+frame.file),character+" missing frame")
	for swapped in [false,true]:
		var b = make_battle(swapped)
		var p = b.fighters[0]
		var q = b.fighters[1]
		var start: float = p.pos.x
		b.tick([{ "right":true },{}])
		check(p.pos.x>start,p.id+" walking")
		b.tick([{ "jump_pressed":true },{}])
		check(p.pos.y<b.floor_y,p.id+" jumping")
		for n in range(60): b.tick([{},{}])
		check(p.pos.y==b.floor_y,p.id+" lands")
		b.dispose()
		for label in ["砍1","砍技1","砍技2","招1","招2","招3","摔1","摔2","必杀","上必杀","超必杀","跳砍","跳招"]:
			b = make_battle(swapped)
			p = b.fighters[0];q = b.fighters[1]
			p.pos.x=400;q.pos.x=435
			q.hp=100000
			if label.begins_with("跳"):p.pos.y-=100;q.pos.y-=100
			if label == "招3" and p.id == "ichigo": q.pos.y-=70
			p.play(label)
			var damage := 0.0
			for n in range(300):
				b.tick([{},{}])
				if p.mode == Fighter.FREE: break
			damage=100000-q.hp
			check(p.mode == Fighter.FREE,p.id+" action never ends: "+label)
			print(p.id," ",label," damage=",damage," unsupported=",b.unsupported_events)
			check(damage>0,p.id+" action misses target fixture: "+label)
			b.dispose()
	# Frontal guard reduces damage; a rear hit does not.
	var b=make_battle();var p=b.fighters[0];var q=b.fighters[1]
	q.guarding=true
	var hit: Dictionary=p.data.actions.k1
	check(q.receive_hit(hit,p,1),"guard receives hit")
	check(is_equal_approx(q.hp,1000-hit.power*0.05),"frontal guard chip damage")
	q.invulnerability=0;q.facing=1
	q.receive_hit(hit,p,1)
	check(q.hp<990,"back attack defeats guard")
	b.dispose()
	# Insufficient meter rejects super; 100 meter consumes exactly 100 on start.
	b=make_battle();p=b.fighters[0]
	b.tick([{ "super_pressed":true },{}])
	check(p.mode==Fighter.FREE,"super cannot use empty meter")
	p.qi=100;b.tick([{ "super_pressed":true },{}])
	check(p.action=="必杀" and p.qi==0,"super meter consumption")
	b.dispose()
	# A lethal hit closes the round and disables subsequent simulation.
	b=make_battle();p=b.fighters[0];q=b.fighters[1]
	q.hp=1;p.pos.x=400;q.pos.x=425;p.play("砍1")
	for n in range(30):b.tick([{},{}])
	check(b.finished and q.hp==0,"KO ends round")
	var count: int=b.tick_count;b.tick([{},{}]);check(b.tick_count==count,"round cannot continue after KO")
	b.dispose()
	# Identical input streams produce identical outcomes.
	var first=make_battle();var second=make_battle()
	for n in range(240):
		var keys: Array=[{"right":n<20,"attack_pressed":n%20==0,"skill_pressed":n%55==0},{"left":n<20,"attack_pressed":n%21==0}]
		first.tick(keys);second.tick(keys)
	check(first.fighters[0].hp==second.fighters[0].hp and first.fighters[1].pos==second.fighters[1].pos,"deterministic replay")
	first.dispose();second.dispose()
	# Exercise the actual game CPU policy through a whole unattended round.
	b=make_battle()
	var game = load("res://scripts/game.gd").new()
	game.battle=b
	game.ai_rng.seed=340
	for n in range(4000):
		b.tick([{},game.ai_input()])
		if b.finished:break
	check(b.finished and b.fighters[0].hp==0,"CPU can reach and KO the opponent")
	game.battle=null
	game.free()
	b.dispose()
	print("CHECKS: ",checks," FAILURES: ",failures.size())
	quit(0 if failures.is_empty() else 1)
