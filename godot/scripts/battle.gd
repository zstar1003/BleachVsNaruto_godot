class_name BVNBattle
extends RefCounted

var fighters: Array = []
var projectiles: Array = []
var effects: Array = []
var sound_events: Array = []
var voice_events: Array = []
var unsupported_events: Dictionary = {}
var floor_y := 365.0
var width := 1000.0
var tick_count := 0
var time_left := 99.0
var time_limit := true
var winner_side := -1
var finished := false
var winner := ""
var training := false
var combat_enabled := true
var shake := 0
var slow_frames := 0
var assist_ids := ["kon","itachi"]
var assist_meter := [100.0,100.0]
var platforms: Array = []
var assist_contexts: Array = []
var projectile_records: Array = []
var effect_library: Dictionary = {}
var shadows: Array = []
var score := 0
var scoring := false
var score_rate := 1.0
var last_attack_bisha := [false,false]
var freeze_frames := 0
var combo := [0,0]
var combo_timeout := [0,0]

func _init(left: Dictionary, right: Dictionary):
	if FileAccess.file_exists("res://assets/full/effects/library.json"): effect_library=JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/effects/library.json"))
	fighters = [BVNFighter.new(left, Vector2(388, floor_y),1),BVNFighter.new(right,Vector2(638,floor_y),-1)]
	for fighter in fighters: fighter.world = self

func opponent(fighter):
	var owner = fighter.owner_fighter if fighter is BVNFighter and fighter.owner_fighter!=null else fighter
	return fighters[1] if owner == fighters[0] else fighters[0]

func tick(inputs: Array):
	if finished: return
	var cutin: Array = effects.filter(func(e):return e.kind=="super")
	if not cutin.is_empty():
		sound_events.clear();voice_events.clear()
		for e in cutin: e.owner.advance_cutin()
		tick_effects()
		return
	tick_count += 1
	for trail in shadows.duplicate():
		trail.alpha-=0.1
		if trail.alpha<=0: shadows.erase(trail)
	if tick_count%3==0:
		for f in fighters:
			if f.script_state.has("shadow"):
				var info=f.data.frames[clampi(f.frame-1,0,f.data.frames.size()-1)]
				if info: shadows.append({"path":"res://assets/full/"+f.data.get("asset_base","")+info.file,"pos":f.pos,"direct":f.facing,"offset":info.offset,"color":f.script_state.shadow,"alpha":0.7})
	shake = maxi(0,shake-1)
	sound_events.clear()
	voice_events.clear()
	if combat_enabled and not training and time_limit: time_left = maxf(0,time_left-1.0/30)
	for i in range(2):
		if fighters[1-i].action_state() not in [21,22]: combo[i]=0
		fighters[i].tick(inputs[i])
		assist_meter[i]=minf(100,assist_meter[i]+0.15)
		if inputs[i].get("assist_pressed",false) and assist_meter[i]>=100 and fighters[i].action_state() in [0,20]: spawn_assist(i);assist_meter[i]=0
	if absf(fighters[0].pos.x-fighters[1].pos.x) < 18 and absf(fighters[0].pos.y-fighters[1].pos.y) < 35:
		var shift: float = (18-absf(fighters[0].pos.x-fighters[1].pos.x))*0.5
		var direction: float = signf(fighters[1].pos.x-fighters[0].pos.x)
		if direction == 0: direction = 1
		fighters[0].pos.x -= shift*direction
		fighters[1].pos.x += shift*direction
	# Both attack boxes are sampled before either hit changes the receiver's state.
	var pending: Array = []
	for fighter in fighters:
		var target = opponent(fighter)
		var collision: Dictionary = fighter.collision_data()
		if fighter.hit_check != "" and collision.checks.has(fighter.hit_check):
			if fighter.world_rect(collision.checks[fighter.hit_check]).intersects(target.hurtbox()):
				fighter.play(fighter.hit_action)
		if fighter.mode != BVNFighter.ACTION or not combat_enabled: continue
		for area in collision.hits:
			if not fighter.data.actions.has(area.id): continue
			var action: Dictionary = fighter.data.actions[area.id]
			# Fired objects are removed from the fighter display in the Flash version.
			if fighter.data.spawns.has(area.id+"atm"): continue
			if fighter.hit_history.has(area.id): continue
			if fighter.world_rect(area.rect).intersects(target.hurtbox()):
				pending.append({"source":fighter,"target":target,"hit":action.merged({"id":area.id}),"id":area.id})
	for item in pending:
		if item.target.receive_hit(item.hit,item.source,item.source.facing):
			item.source.hit_history[item.id] = true
			item.source.just_hits[item.id] = true
			register_hit(item.source,item.target,item.hit)
	for projectile in projectiles.duplicate():
		projectile.age += 1
		if projectile.owner.owner_fighter!=null:
			projectile.owner.pos=projectile.pos
			projectile.owner.frame=projectile.frame+1
		var target = opponent(projectile.owner)
		if projectile.sprite.has("program") and not projectile.stopped:
			BVNTimelineVM.run(projectile.sprite.program.get(str(projectile.frame+1),[]),projectile.owner,projectile.state,projectile)
		for sound in projectile.sprite.get("sounds",{}).get(str(projectile.frame+1),[]): voice_events.append({"character":projectile.owner.id,"sound":sound,"full":true})
		if projectile.hit_check!="":
			var checks: Dictionary = projectile.sprite.get("checks",[])[clampi(projectile.frame,0,projectile.sprite.checks.size()-1)] if projectile.sprite.has("checks") and not projectile.sprite.checks.is_empty() else {}
			var area=checks.get(projectile.hit_check,null)
			if area==null:
				for box in projectile.sprite.collisions[clampi(projectile.frame,0,projectile.sprite.collisions.size()-1)]:
					if box.id+"atm"==projectile.hit_check or box.id==projectile.hit_check: area=box.rect
			if area!=null and projectile_rect(projectile,area).intersects(target.hurtbox()):
				attacker_call(projectile,"gotoAndPlay",[projectile.hit_action]);projectile.hit_check=""
		if projectile.custom_func!="":
			BVNTimelineVM.run(projectile.owner.data.get("methods",{}).get(projectile.custom_func,[]),projectile.owner,projectile.state,projectile)
		if not projectiles.has(projectile): continue
		if projectile.attacker:
			for event in projectile.sprite.get("events",{}).get(str(projectile.frame+1),[]):
				var args: Array = event.args
				match event.method:
					"move": projectile.velocity = Vector2(float(args[0])*projectile.facing,float(args[1]) if args.size()>1 else 0.0)
					"damping": projectile.damping = Vector2(float(args[0]),float(args[1]) if args.size()>1 else 0.0)
					"stopMove": projectile.velocity = Vector2.ZERO
					"endAct": projectile.active = false
			projectile.pos += projectile.velocity*float(projectile.get("speedLevel",1))
			for axis in ["x","y"]:
				var param: Dictionary = projectile.params.get(axis,{})
				if param.get("followTarget",false) or param.get("moveToTarget",false): projectile.pos[axis]=target.pos[axis]+float(param.get("offset",0))*(projectile.facing if axis=="x" else 1)
			if projectile.params.get("applyG",false): projectile.velocity.y+=1.2
			if projectile.pos.y>=floor_y:
				projectile.pos.y=floor_y
				if projectile.floor_action!="": attacker_call(projectile,"gotoAndPlay",[projectile.floor_action]);projectile.floor_action=""
			projectile.velocity.x = move_toward(projectile.velocity.x,0,projectile.damping.x)
			if projectile.params.get("x",{}).get("moveToTarget",false): projectile.pos.x = target.pos.x
		else:
			projectile.pos += projectile.velocity*float(projectile.get("speedLevel",1))
			for axis in ["x","y"]:
				var v: Dictionary = projectile.params.get(axis,{})
				if v.has("add"):
					var current: float = projectile.velocity[axis] * (projectile.facing if axis == "x" else 1)
					var limit: float = v.get("max",100)
					current = minf(current+v.add,limit) if v.add > 0 else maxf(current+v.add,limit)
					projectile.velocity[axis] = current * (projectile.facing if axis == "x" else 1)
		if p_touch_side(projectile):
			attacker_call(projectile,"gotoAndPlay",[projectile.side_action]);projectile.erase("side_action")
		var sprite: Dictionary = projectile.sprite
		var frame_index: int = clampi(projectile.frame,0,sprite.frames.size()-1)
		for area in sprite.collisions[frame_index]:
			if not projectile.active or not combat_enabled or not projectile.owner.data.actions.has(area.id): continue
			if projectile.age-projectile.last_hit < 5: continue
			var rect := projectile_rect(projectile,area.rect)
			if rect.intersects(target.hurtbox()):
				var hit: Dictionary = projectile.owner.data.actions[area.id].merged({"id":area.id})
				if target.receive_hit(hit,projectile,projectile.facing):
					register_hit(projectile.owner,target,hit)
					projectile.last_hit = projectile.age
					projectile.hits -= 1
					projectile.owner.just_hits[area.id] = true
		if projectile.attacker:
			if not projectile.stopped: projectile.frame += 1
		else:
			projectile.frame += 1
			if sprite.labels.has("loop") and projectile.frame >= int(sprite.labels.loop):
				var start: int = int(sprite.labels.get("loop_start",1))-1
				projectile.frame = start
		if projectile.age > projectile.lifetime or projectile.hits <= 0 or projectile.pos.x < -150 or projectile.pos.x > width+150 or (projectile.attacker and projectile.frame >= sprite.frames.size()):
			projectiles.erase(projectile)
	tick_effects()
	if training:
		for fighter in fighters:
			fighter.qi = 300
			if fighter.hp <= 0:
				fighter.hp = fighter.max_hp
				fighter.hurt_stage=0;fighter.hurt_frames=0
				fighter.idle()
	else:
		if combat_enabled and (fighters[0].hp <= 0 or fighters[1].hp <= 0 or (time_limit and time_left <= 0)):
			finished = true
			winner_side=-1 if fighters[0].hp==fighters[1].hp else (0 if fighters[0].hp>fighters[1].hp else 1)
			winner = "平局" if fighters[0].hp == fighters[1].hp else (fighters[0].data.name if fighters[0].hp > fighters[1].hp else fighters[1].data.name)
			for fighter in fighters:
				if fighter.hp > 0: fighter.set_pose("胜利")

func tick_effects():
	for effect in effects.duplicate():
		effect.time-=1
		effect.age=int(effect.get("age",0))+1
		if effect.time<=0: effects.erase(effect)

func add_visual(id: String,point: Vector2,direct := 1):
	var model: Dictionary = effect_library.get("models",{}).get(id,{})
	var sprite: Dictionary = effect_library.get("symbols",{}).get(model.get("symbol",""),{})
	if sprite.is_empty(): return
	if model.has("freeze"): freeze_frames=maxi(freeze_frames,int(float(model.freeze)*0.03))
	effects.append({"kind":"visual","data":sprite,"pos":point,"direct":direct,"time":sprite.frames.size(),"age":0,"blend":model.get("blendMode",""),"rotation":randf_range(-PI,PI) if model.get("randRotate",false) else 0})
	if model.has("sound") and effect_library.sounds.has(model.sound): voice_events.append({"character":"effect","sound":{"file":effect_library.sounds[model.sound],"start":0,"end":0,"stop":false},"full":true})

func p_touch_side(p: Dictionary) -> bool:
	return p.has("side_action") and (p.pos.x<=0 or p.pos.x>=width)

func register_hit(source,target,hit: Dictionary):
	source.qi = minf(300,source.qi+minf(15,float(hit.power)*0.16))
	var side: int = fighters.find(source.owner_fighter if source.owner_fighter!=null else source)
	var is_bisha: bool = str(hit.get("id","")).find("bs")>=0
	last_attack_bisha[side]=is_bisha
	if target.action_state() in [21,22]:
		combo[side] += 1
		combo_timeout[side] = 45
		if scoring and side==0:
			var points: int = int(float(hit.power)*(2 if is_bisha else 1))
			if str(hit.get("id","")) in ["sh1","sh2"]: points+=500
			if hit.get("isBreakDef",false): points+=200
			if int(hit.get("hurtType",0))==1: points+=200
			points+=combo[side]*(50 if combo[side]<4 else 100)
			score+=int(points*score_rate)
	var type: int = int(hit.get("hitType",0))
	if type>0: add_visual(("defense_" if target.guarding else "hit_")+str(type),target.hurtbox().get_center(),target.facing)
	shake = 3

func mirrored_rect(point: Vector2, values: Array, facing: int) -> Rect2:
	return Rect2(point+Vector2(values[0] if facing>0 else -values[0]-values[2],values[1]),Vector2(values[2],values[3]))

func spawn(owner, name: String, params: Dictionary, attacker: bool):
	if not owner.data.spawns.has(name):
		unsupported_events[name] = true
		return
	var sprite: Dictionary = owner.data.spawns[name]
	params=params.duplicate(true)
	var extra_offset := Vector2.ZERO
	for axis in ["x","y"]:
		var raw=params.get(axis,{})
		if raw is float or raw is int:
			if attacker: extra_offset[axis]=float(raw)*(owner.facing if axis=="x" else 1);params[axis]={}
			else: params[axis]={"start":raw}
	var offset := Vector2(sprite.position[0]*owner.facing,sprite.position[1])+extra_offset
	var speed_x: float = params.get("x",{}).get("start",0)
	var speed_y: float = params.get("y",{}).get("start",0)
	var life: int = ceili(float(params.get("hold",2))*30)
	if attacker: life = sprite.frames.size()+1
	projectiles.append({"name":name,"owner":owner,"sprite":sprite,"params":params,"attacker":attacker,"pos":owner.pos+offset,"velocity":Vector2(speed_x*owner.facing,speed_y),"facing":owner.facing,"age":0,"frame":0,"last_hit":-10,"damping":Vector2.ZERO,"active":true,"hits":int(params.get("hits",100 if attacker else 1)),"lifetime":life,"state":sprite.get("script_defaults",{}).duplicate(true),"stopped":false,"floor_action":"","hit_check":"","hit_action":"","cross_map":false,"custom_func":""})
	projectile_records.append(projectiles[-1])

func dispose():
	for p in projectile_records: p.state.clear()
	projectile_records.clear()
	for fighter in fighters: fighter.world = null;fighter.script_state.clear()
	for context in assist_contexts: context.world=null;context.script_state.clear()
	assist_contexts.clear()
	for p in projectiles:
		if p.owner.owner_fighter!=null: p.owner.world=null
	projectiles.clear()
	effects.clear()
	shadows.clear()
	fighters.clear()

func projectile_rect(projectile: Dictionary, values: Array) -> Rect2:
	var m: Array = projectile.sprite.matrix
	var transform := Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),Vector2.ZERO)
	var rect := Rect2(Vector2(values[0],values[1]),Vector2(values[2],values[3]))
	var transformed: Rect2 = transform * rect
	return mirrored_rect(projectile.pos,[transformed.position.x,transformed.position.y,transformed.size.x,transformed.size.y],projectile.facing)

func transform_fighter(fighter, root_frame: int):
	if not fighter.data.has("source"): return
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/catalog.json"))
	var target_start: int = int(fighter.data.start)+1 if root_frame==0 else root_frame-1
	for entry in catalog.fighter:
		if entry.source==fighter.data.source and int(entry.start)==target_start:
			fighter.controller_call("effect","endWanKai",[])
			shake=0
			fighter.data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+entry.id+".json"))
			fighter.script_state=fighter.data.get("script_defaults",{}).duplicate(true)
			fighter.id=entry.id
			fighter.script_state.banKai=true
			fighter.frame=int(fighter.data.labels.get("站立",1))
			fighter.action="站立"
			fighter.idle()
			return
	unsupported_events["Missing transformation "+str(target_start)]=true

func attacker_call(p: Dictionary,method: String,args: Array):
	var a=args[0] if args.size()>0 else 0
	var b=args[1] if args.size()>1 else 0
	match method:
		"move": p.velocity=Vector2(float(a)*p.facing,float(b))
		"damping": p.damping=Vector2(float(a),float(b))
		"stopMove": p.velocity=Vector2.ZERO
		"endAct": p.active=false
		"removeSelf": projectiles.erase(p)
		"stop": p.stopped=true
		"gotoAndPlay", "gotoAndStop":
			if p.sprite.labels.has(str(a)):
				p.frame=int(p.sprite.labels[str(a)])-1
				p.stopped=method=="gotoAndStop"
		"moveToTarget":
			if a!=null: p.pos.x=opponent(p.owner).pos.x+float(a)*p.facing
			if b!=null: p.pos.y=opponent(p.owner).pos.y+float(b)
		"setTouchFloor": p.floor_action=str(a)
		"setHitTarget":
			p.hit_check=str(a)
			p.hit_action=str(b)
		"justHit": return p.owner.just_hits.has(str(a))
		"stopFollowTarget":
			p.params.get("x",{}).followTarget=false
			p.params.get("y",{}).followTarget=false
		"fire", "addAttacker": spawn(p.owner,str(a),b if b is Dictionary else {},method=="addAttacker")
		"setDirectToTarget": p.facing=1 if opponent(p.owner).pos.x>p.pos.x else -1
		"setTouchSide": p.side_action=str(a)
		"setCrossMap": p.cross_map=bool(a)
		_: unsupported_events["attacker."+method]=true
	return null

func spawn_assist(side: int):
	var path: String = "res://assets/full/assist/"+assist_ids[side]+".json"
	if not FileAccess.file_exists(path): return
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var f=BVNFighter.new(d,fighters[side].pos+Vector2(-45*fighters[side].facing,0),fighters[side].facing)
	f.owner_fighter=fighters[side]
	assist_contexts.append(f)
	f.world=self
	var sprite: Dictionary = d.duplicate()
	sprite.collisions=[]
	sprite.checks=[]
	for c in d.collisions: sprite.collisions.append(c.hits);sprite.checks.append(c.checks)
	sprite.matrix=[1,0,0,1,0,0]
	projectiles.append({"name":"assist_"+assist_ids[side],"owner":f,"sprite":sprite,"params":{},"attacker":true,"pos":f.pos,"velocity":Vector2.ZERO,"facing":f.facing,"age":0,"frame":1,"last_hit":-10,"damping":Vector2.ZERO,"active":true,"hits":1000,"lifetime":d.frames.size()+1,"state":d.get("script_defaults",{}).duplicate(),"stopped":false,"floor_action":"","hit_check":"","hit_action":"","cross_map":false,"custom_func":""})
	projectile_records.append(projectiles[-1])

func assister_call(p: Dictionary,method: String,args: Array):
	match method:
		"getOwner": return p.owner.owner_fighter
		"getTarget": return opponent(p.owner)
		"getSelf": return p.owner
		"getAttacker":
			for projectile in projectiles:
				if projectile.owner==p.owner and projectile.name==args[0]: return projectile
			return null
		"getGameSprites": return projectiles
		"isBullet": return args[0] is Dictionary and args[0].has("attacker") and not args[0].attacker
		"addCustomFunc": p.custom_func=args[0].get("script_method","") if args.size()>0 and args[0] is Dictionary else ""
		"removeCustomFunc": p.custom_func=""
		"checkHitOwner":
			var col: Dictionary = p.owner.data.collisions[clampi(p.frame,0,p.owner.data.collisions.size()-1)]
			return col.checks.has(args[0]) and p.owner.world_rect(col.checks[args[0]]).intersects(p.owner.owner_fighter.hurtbox())
		"setApplyG": p.params.applyG=args[0]
		"finish": projectiles.erase(p)
		"moveOnce": p.pos+=Vector2(float(args[0])*p.facing,float(args[1]) if args.size()>1 else 0.0)
		_: return attacker_call(p,method,args)
	return null
