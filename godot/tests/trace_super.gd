extends SceneTree
const Battle=preload("res://scripts/battle.gd")
func _initialize():
	var a=JSON.parse_string(FileAccess.get_file_as_string("res://assets/naruto/fighter.json"))
	var b=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ichigo/fighter.json"))
	var w=Battle.new(a,b);var p=w.fighters[0];var q=w.fighters[1]
	p.pos.x=400;q.pos.x=435;q.hp=100000;p.play("超必杀")
	for n in range(250):
		w.tick([{},{}])
		if n%10==0 or not w.projectiles.is_empty():print(n," ",p.action," frame=",p.frame," pos=",p.pos," enemy=",q.pos," hp=",q.hp," proj=",w.projectiles.size())
		if not w.projectiles.is_empty():
			var pr=w.projectiles[0];print(pr.name," ",pr.pos," rect=",w.mirrored_rect(pr.pos,pr.sprite.collisions[pr.frame][0].rect,pr.facing) if not pr.sprite.collisions[pr.frame].is_empty() else "none")
	w.dispose();quit()
