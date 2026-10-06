extends SceneTree

var checks := 0
var failures: Array = []
func check(value: bool,message: String):
	checks+=1
	if not value: failures.append(message)

func fighter(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+id+".json"))

func _init(): run.call_deferred()

func run():
	var match_state := BVNMatch.new()
	match_state.configure([["ichigo"],["naruto"]],false,false,false,0)
	for n in range(2):
		var battle := BVNBattle.new(fighter("ichigo"),fighter("naruto"))
		match_state.apply(battle,2,60)
		check(battle.fighters[0].max_hp==2000,"LIFE doubles maximum health")
		battle.fighters[1].hp=0
		battle.tick([{},{}])
		match_state.finish_round(battle)
		check(match_state.complete==(n==1),"single match requires two wins")
		battle.dispose()
	match_state=BVNMatch.new()
	match_state.configure([["ichigo","rukia","renji"],["naruto","sakura","sasuke"]],true,false,false,0)
	var battle := BVNBattle.new(fighter("ichigo"),fighter("naruto"))
	match_state.apply(battle,1,-1)
	battle.fighters[0].hp=500
	battle.fighters[1].qi=50
	battle.fighters[1].hp=0
	battle.tick([{},{}])
	check(battle.time_left==-1 and battle.finished,"infinite clock permits KO")
	match_state.finish_round(battle)
	check(not match_state.complete and match_state.fighter_id(1)=="sakura","team loser advances to next selected fighter")
	check(match_state.carry[0].hp==665,"team winner recovers 33% of missing HP with infinite time")
	check(match_state.carry[1].qi==150,"same comic successor inherits qi plus 100")
	battle.dispose()
	match_state=BVNMatch.new()
	match_state.configure([["ichigo"],["naruto"]],false,true,false,0)
	check(match_state.missions.size()==8,"original eight arcade stages")
	check(match_state.mission.map=="KonohaMura","original first mission map")
	for n in range(7): check(match_state.next_mission(),"arcade mission progression "+str(n))
	check(not match_state.next_mission(),"arcade ends after eight stages")
	battle=BVNBattle.new(fighter("ichigo"),fighter("madara"))
	match_state.apply(battle,1,90)
	check(battle.fighters[1].max_hp==2000 and battle.fighters[1].attack_rate==2,"original final boss modifiers")
	battle.dispose()
	for id in ["KonohaMura","Forest","Roof","DanGai"]:
		var path: String = "res://assets/maps/"+id+"/map.json"
		if not FileAccess.file_exists(path): continue
		var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(map.bottom==600 and map.floor<=600,"normalized map coordinate system "+id)
	for scenario in [["ichigo",{},"ichigo_bankai"],["ichigo",{"down":true},"ichigo_vizored_half"],["naruto",{},"naruto_oneTail"],["rukia",{},"rukia_shikai"]]:
		battle=BVNBattle.new(fighter(scenario[0]),fighter("naruto"))
		battle.fighters[0].qi=300
		var keys: Dictionary = scenario[1].merged({"transform_pressed":true})
		battle.tick([keys,{}])
		var cutin_time: float = -1
		for n in range(250):
			if battle.effects.any(func(e):return e.kind=="super"):
				if cutin_time<0: cutin_time=battle.time_left
				battle.tick([{},{}])
				check(battle.time_left==cutin_time,"cut-in pauses round clock "+str(scenario[0]))
			else:
				cutin_time=-1
				battle.tick([{},{}])
		check(battle.fighters[0].id==scenario[2],"original transformation destination "+str(scenario[0]))
		check(not battle.effects.any(func(e):return e.kind=="super"),"transformation resumes both fighters "+str(scenario[0]))
		battle.dispose()
	battle=BVNBattle.new(fighter("ichigo"),fighter("naruto"))
	battle.scoring=true
	var hit := {"id":"k1","power":40,"hitType":1,"hitx":0,"hity":0,"hurtTime":300,"hurtType":0}
	battle.fighters[1].receive_hit(hit,battle.fighters[0],1)
	battle.register_hit(battle.fighters[0],battle.fighters[1],hit)
	check(battle.score==90,"original score: 40 power plus 50 first-hit bonus")
	check(battle.combo[0]==1,"combo begins on successful hurt")
	battle.fighters[1].idle()
	battle.tick([{},{}])
	check(battle.combo[0]==0,"combo ends when opponent recovers")
	battle.dispose()
	var game=load("res://scripts/game.gd").new()
	root.add_child(game)
	await process_frame
	game.original_ui.activate_menu(3,false)
	check(game.original_ui.mode=="cpu" and game.training_mode,"training uses sequential P1 selection")
	game.original_ui.confirm(0)
	check(game.original_ui.confirmed[0] and not game.original_ui.confirmed[1],"training chooses both fighters sequentially")
	game.original_ui.submenu=1
	game.original_ui.activate_menu(0,true)
	check(game.screen=="howtoplay","arcade opens original tutorial")
	game.original_ui.selected=[["ichigo"],["naruto"]]
	game.original_ui.launch_battle()
	await process_frame
	for screen in ["menu","select","map","settings","keys","credits","howtoplay","battle","winner","continue","congratulations"]:
		game.screen=screen
		game.original_ui.queue_redraw()
		await process_frame
		check(game.original_ui.data.size()>0,"UI scene rendered "+screen)
	game.screen="battle"
	game.paused=true
	game.original_ui.queue_redraw()
	await process_frame
	game.show_help=true
	game.original_ui.queue_redraw()
	await process_frame
	game.queue_free()
	await process_frame
	print("MODE / UI CHECKS ",checks," FAILURES ",failures.size())
	for message in failures: print("FAIL ",message)
	quit(1 if failures.size()>0 else 0)
