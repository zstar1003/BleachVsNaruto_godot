class_name BVNAI
extends RefCounted

var data: Dictionary
var state: Dictionary = {}
var world: BVNBattle
var fighter: BVNFighter
var rng := RandomNumberGenerator.new()
var orders: Array = []
const ACTION_KEYS = {"attack":"attack","attackAIR":"attack_air","skillAIR":"skill_air","bishaAIR":"bisha_air","skill1":"skill1","skill2":"skill2","zhao1":"zhao1","zhao2":"zhao2","zhao3":"zhao3","catch1":"catch1","catch2":"catch2","bisha":"bisha","bishaUP":"bisha_up","bishaSUPER":"bisha_super"}

func _init(owner_fighter: BVNFighter,level: int,seed_value: int):
	fighter=owner_fighter
	world=fighter.world
	if not fighter.data.has("ai_ranges"):
		var path: String = "res://assets/full/fighter/"+fighter.id+".json"
		if FileAccess.file_exists(path): fighter.data.ai_ranges=JSON.parse_string(FileAccess.get_file_as_string(path)).get("ai_ranges",{})
	rng.seed=seed_value
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/ai.json"))
	state=data.script_defaults.duplicate(true)
	state.AILevel=clampi(level,1,6)
	state.GameConfig={"FPS_GAME":60,"SPEED_PLUS":0.5,"SPEED_PLUS_DEFAULT":0.5}
	state.FighterActionState=data.constants.duplicate()
	state.FighterActionState.native="states"
	state.super={"controller":"ai_base"}
	for type in ["Bullet","FighterAttacker","Assister","Array"]: state[type]={"runtime_type":type}

func dispose():
	state.clear()
	world=null
	fighter=null

func decide() -> Dictionary:
	var result := {}
	for step in range(2):
		BVNTimelineVM.run_function("render",[],self,state)
		result.left=state.get("moveLeft",false)
		result.right=state.get("moveRight",false)
		result.down=state.get("defense",false)
		for pair in [["jump","jump_pressed"],["dash","dash_pressed"],["assist","assist_pressed"],["ghostStep","ghost_pressed"],["specialSkill","special_pressed"]]:
			if state.get(pair[0],false): result[pair[1]]=true
		if state.get("jumpDown",false): result.down=true;result.jump_pressed=true
		for action in ACTION_KEYS:
			if state.get(action,false) and state.get("_fighterAction",{}).get(action,false): result.request_action=ACTION_KEYS[action]
	return result

func controller_call(controller: String,method: String,args: Array):
	if data.methods.has(method) and controller!="ai_base": return BVNTimelineVM.run_function(method,args,self,state)
	var target: BVNFighter = world.opponent(fighter)
	match method:
		"render":
			state._fighter=fighter
			state._target=target
			state._targetFighter=target
			state._isConting=fighter.action_state() in [10,11,12,13]
			state._fighterAction=fighter.controller_call("mc","getAction",[])
			orders.clear()
			BVNTimelineVM.run_function("updateActionAI",[],self,state)
			orders.sort_custom(func(a,b): return a.order>b.order)
			for i in range(1,orders.size()): state[orders[i].id]=false
		"getAIResult": return rng.randf()*10<float(args[clampi(int(state.AILevel)-1,0,args.size()-1)])
		"getAIByFighterState":
			var rates: Array = args[0].get(str(target.action_state()),args[0].get("defult",[0,0,0,0,0,0]))
			return controller_call("base","getAIResult",rates)
		"getTargetDistance":
			var position: Vector2 = args[0].pos
			var delta := (position-fighter.pos).abs()
			return {"x":delta.x,"y":delta.y}
		"targetCanBeHit": return target.hp>0 and target.invulnerability<=0
		"targetInRange":
			var range=fighter.data.get("ai_ranges",{}).get(str(args[0]),null)
			return range!=null and fighter.world_rect(range).intersects(target.hurtbox())
		"isBreakAct", "isHitDownAct":
			for id in fighter.data.actions:
				if str(id).begins_with(str(args[0])):
					var hit: Dictionary = fighter.data.actions[id]
					if hit.get("isBreakDef",false) if method=="isBreakAct" else int(hit.get("hurtType",0))==1: return true
			return false
		"addContOrder":
			for order in orders:
				if order.id==args[0]: order.order=args[1];return null
			orders.append({"id":args[0],"order":args[1]})
		"isHurting": return int(args[0]) in [21,22,23,24]
		_: world.unsupported_events["AI."+method]=true
	return null
