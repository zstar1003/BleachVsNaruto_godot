class_name BVNFighter
extends RefCounted

const FREE = 0
const ACTION = 1
const HURT = 2
const KO = 3
const DEFAULT_ACTIONS = {"attack":"砍1", "skill1":"砍技1", "skill2":"砍技2", "zhao1":"招1", "zhao2":"招2", "zhao3":"招3", "catch1":"摔1", "catch2":"摔2", "bisha":"必杀", "bisha_up":"上必杀", "bisha_super":"超必杀", "attack_air":"跳砍", "skill_air":"跳招", "bisha_air":"跳必杀", "wankai":"万解","wankai_up":"万解W","wankai_down":"万解S"}
const SET_ACTIONS = {"setAttack":"attack", "setSkill1":"skill1", "setSkill2":"skill2", "setZhao1":"zhao1", "setZhao2":"zhao2", "setZhao3":"zhao3", "setCatch1":"catch1", "setCatch2":"catch2", "setBisha":"bisha", "setBishaUP":"bisha_up", "setBishaSUPER":"bisha_super", "setAttackAIR":"attack_air", "setSkillAIR":"skill_air", "setBishaAIR":"bisha_air", "setWankai":"wankai","setWankaiW":"wankai_up","setWankaiS":"wankai_down"}
var data: Dictionary
var id: String
var pos := Vector2.ZERO
var ground_y := 365.0
var drop_frames := 0
var velocity := Vector2.ZERO
var damping := Vector2.ZERO
var facing := 1
var hp := 1000.0
var max_hp := 1000.0
var attack_rate := 1.0
var qi := 0.0
var energy := 100.0
var mode := FREE
var frame := 1
var action := "站立"
var age := 0
var serial := 0
var stun := 0
var invulnerability := 0
var steel := false
var super_steel := false
var apply_gravity := true
var guarding := false
var jumps := 0
var allowed: Dictionary = {}
var just_hits: Dictionary = {}
var hit_history: Dictionary = {}
var buffered := ""
var buffer_age := 0
var floor_action := ""
var hit_check := ""
var hit_action := ""
var stopped := false
var flash := 0
var air_move := true
var last_input: Dictionary = {}
var world
var script_state: Dictionary = {}
var visible := true
var owner_fighter
var buff_state: Dictionary = {}
var assist_meter := 100.0
var is_cross := false
var move_target: Dictionary = {}
var hurt_action := ""
var gravity := 0.0
var hurt_stage := 0
var hurt_frames := 0
var hurt_min_y := 0.0
var hurt_heavy := false
var last_damage := 0.0
var hurt_damage := 0.0
var last_hit_bisha := false
var ghost_frames := 0
var energy_cooldown := 0

func _init(character: Dictionary, start: Vector2, direction: int):
	data = character
	id = data.id
	pos = start
	ground_y=start.y
	script_state=character.get("script_defaults",{}).duplicate()
	facing = direction
	reset_allowed()

func reset_allowed():
	allowed = DEFAULT_ACTIONS.duplicate()

func in_air() -> bool:
	return pos.y < ground_y - 0.01

func end_frame(label: String) -> int:
	var start: int = int(data.labels[label])
	var end: int = data.frames.size()
	for value in data.labels.values():
		if int(value) > start:
			end = mini(end, int(value) - 1)
	return end

func set_pose(label: String):
	if not data.labels.has(label):
		return
	if action == label:
		return
	action = label
	frame = int(data.labels[label])
	age = 0
	stopped = false

func play(label: String):
	if not data.labels.has(label):
		return
	action = label
	frame = int(data.labels[label])
	age = 0
	serial += 1
	mode = ACTION
	allowed.clear()
	just_hits.clear()
	hit_history.clear()
	guarding = false
	floor_action = ""
	hit_check = ""
	stopped = false
	steel = false
	apply_gravity = true
	air_move = false
	invulnerability = 0
	velocity.x = 0
	damping.x=0
	run_events()

func idle():
	mode = FREE
	steel = false
	super_steel = false
	apply_gravity = true
	air_move = true
	guarding = false
	floor_action = ""
	hit_check = ""
	reset_allowed()
	if in_air():
		set_pose("落")
	else:
		velocity = Vector2.ZERO
		damping = Vector2.ZERO
		set_pose("站立")

func input_action(keys: Dictionary) -> String:
	if keys.has("request_action"): return keys.request_action
	var up: bool = keys.get("up", false)
	var down: bool = keys.get("down", false)
	if keys.get("transform_pressed",false) or keys.get("attack",false) and keys.get("jump",false):
		return "wankai_up" if up else ("wankai_down" if down else "wankai")
	if keys.get("attack_pressed", false):
		if in_air(): return "attack_air"
		if keys.get("left",false) or keys.get("right",false):
			if pos.distance_to(world.opponent(self).pos) < 35: return "catch1"
		return "skill2" if up else ("skill1" if down else "attack")
	if keys.get("skill_pressed", false):
		if in_air(): return "skill_air"
		if keys.get("left",false) or keys.get("right",false):
			if pos.distance_to(world.opponent(self).pos) < 35: return "catch2"
		return "zhao3" if up else ("zhao2" if down else "zhao1")
	if keys.get("super_pressed", false) and in_air(): return "bisha_air"
	if keys.get("super_pressed", false) and not in_air():
		return "bisha_up" if up else ("bisha_super" if down else "bisha")
	return ""

func advance_cutin():
	if not stopped:
		frame+=1
		if frame>data.frames.size(): idle()
		else: run_events()

func tick(keys: Dictionary):
	last_input = keys
	age += 1
	if script_state.get("custom_func","")!="":
		BVNTimelineVM.run(data.get("methods",{}).get(script_state.custom_func,[]),self,script_state)
	for key in buff_state.keys():
		buff_state[key].frames-=1
		if buff_state[key].frames<=0: buff_state.erase(key)
	flash = maxi(0, flash - 1)
	invulnerability = maxi(0, invulnerability - 1)
	energy_cooldown=maxi(0,energy_cooldown-1)
	if energy_cooldown==0: energy=minf(100,energy+(0.8 if guarding else (1.1 if mode==ACTION else 2.0)))
	if ghost_frames>0:
		ghost_frames-=1
		physics_step()
		if ghost_frames==0: is_cross=false;idle()
		return
	if mode in [HURT,KO]:
		if mode==HURT and (keys.get("special_pressed",false) or keys.get("assist",false)) and qi>=100 and energy>=50 and hurt_damage<=210 and not last_hit_bisha:
			qi-=100;energy=0;energy_cooldown=24
			idle();hurt_stage=0;hurt_damage=0;invulnerability=15
			if int(data.comic_type)==1:
				world.add_visual("replaceSp",pos,facing)
				pos=world.opponent(self).pos+Vector2(200*facing,0)
				hp=minf(max_hp,hp+last_damage)
			else:
				world.add_visual("explodeSp",pos,facing)
				steel=true;super_steel=true
				world.opponent(self).receive_hit({"power":50,"hitType":5,"hurtType":1,"hitx":15,"hity":0,"hurtTime":0},self,facing)
			return
		physics_step()
		if hurt_stage>0: update_hurt_fly(keys)
		elif mode==HURT:
			stun-=1
			if stun<=0: hurt_damage=0;idle()
		return
	if (keys.get("ghost_pressed",false) or keys.get("dash_pressed",false) and (keys.get("up",false) or keys.get("down",false))) and qi>=60 and energy>=80 and action_state() not in [12,13,50]:
		qi-=60;energy-=80;energy_cooldown=24
		idle();is_cross=true;ghost_frames=12;invulnerability=12
		world.add_visual("ghost_step",pos,facing)
		velocity=Vector2(8*facing,0) if not keys.get("up",false) else Vector2(0,-12)
		damping=Vector2(0,0.1)
		return
	var requested := input_action(keys)
	if requested != "":
		buffered = requested
		buffer_age = 3
	elif buffer_age > 0:
		buffer_age -= 1
	else:
		buffered = ""
	if mode == ACTION and not stopped:
		frame += 1
		if frame > data.frames.size():
			idle()
		else:
			run_events()
	if buffered != "" and (mode == FREE or allowed.has(buffered)):
		var label: String = allowed.get(buffered, DEFAULT_ACTIONS.get(buffered,""))
		var cost := 300.0 if (buffered=="bisha_super" or buffered.begins_with("wankai")) else (100.0 if buffered.begins_with("bisha") else 0.0)
		if qi >= cost and data.labels.has(label):
			qi -= cost
			buffered = ""
			play(label)
	if keys.get("jump_pressed",false) and keys.get("down",false) and ground_y<world.floor_y:
		drop_frames=12;pos.y+=6;ground_y=world.floor_y
	elif keys.get("jump_pressed", false) and not keys.get("attack",false) and jumps < 2 and (mode == FREE or allowed.has("jump")):
		jumps += 1
		idle()
		velocity.y = -float(data.stats.jumpPower)
		damping.y=0.5
		gravity=0
		world.add_visual("jump_air" if jumps>1 else "jump",pos,facing)
		apply_gravity = true
		set_pose("跳")
	if keys.get("dash_pressed",false) and (mode == FREE or allowed.has("dash")) and energy >= 10:
		energy -= 10
		play("瞬步")
		velocity = Vector2(float(data.stats.speed)*2.5*facing,0)
		invulnerability = 10
	if mode == FREE:
		var other = world.opponent(self)
		facing = 1 if other.pos.x >= pos.x else -1
		guarding = keys.get("down",false) and not in_air()
		var direction := int(keys.get("right",false)) - int(keys.get("left",false))
		if guarding:
			velocity.x = 0
			set_pose("防御")
		elif direction != 0:
			velocity.x = direction * float(data.stats.speed)*(1+float(buff_state.get("speedUp",{}).get("value",0)))
			if not in_air(): set_pose("走")
		elif not in_air():
			velocity.x = 0
			set_pose("站立")
		if in_air(): set_pose("跳" if velocity.y < -2 else ("跳中" if velocity.y < 2 else "落"))
		if not stopped:
			frame += 1
			if frame > end_frame(action): frame = int(data.labels[action])
	physics_step()

func physics_step():
	drop_frames=maxi(0,drop_frames-1)
	if not move_target.is_empty():
		var target = world.opponent(self)
		var marker: Array = collision_data().get("markers",{}).get(move_target.get("followmc",""),[0,0])
		var desired: Vector2 = pos+Vector2(marker[0]*facing,marker[1])
		target.pos = target.pos.move_toward(desired,float(move_target.get("speed",20)))
	for substep in range(2):
		var previous_y: float = pos.y
		pos+=velocity*0.5
		velocity.x=move_toward(velocity.x,0,damping.x)
		velocity.y=move_toward(velocity.y,0,damping.y)
		if apply_gravity and pos.y<ground_y:
			if velocity.y<0: gravity=0
			else:
				gravity=minf(12,gravity+0.6)
				pos.y+=gravity*0.5
		ground_y=world.floor_y
		if velocity.y>=0 and velocity.y<2.5 and drop_frames<=0:
			for platform in world.platforms:
				var top: float = platform[1]
				if previous_y<=top+5 and pos.y>=top-5 and pos.x>platform[0] and pos.x<platform[0]+platform[2]: ground_y=minf(ground_y,top)
		if pos.y>=ground_y or ground_y==world.floor_y and pos.y>ground_y-12 and velocity.y>=0:
			var was_air: bool = previous_y<ground_y-5
			pos.y=ground_y
			velocity.y=0
			gravity=4
			jumps=0
			if was_air: world.add_visual("touch_floor",pos,facing)
			if was_air and floor_action!="":
				var landing:=floor_action;floor_action="";play(landing)
		pos.x=clampf(pos.x,10,world.width-10)

func update_hurt_fly(keys: Dictionary):
	hurt_min_y=minf(hurt_min_y,pos.y)
	hurt_frames-=1
	match hurt_stage:
		1:
			if age>1: set_pose("击飞")
			if hurt_frames<=0 and not in_air():
				hurt_stage=2;hurt_frames=2;set_pose("击飞_落")
		2:
			if hurt_frames<=0:
				if hurt_heavy:
					hurt_stage=4;hurt_frames=30;damping.x=4;set_pose("击飞_倒");world.add_visual("hit_floor_heavy",pos,facing)
				else:
					hurt_stage=3;hurt_frames=2;velocity.y=-clampf((pos.y-hurt_min_y)/25,3,8);damping.y=0.5;set_pose("击飞_弹");world.add_visual("hit_floor",pos,facing)
		3:
			if keys.get("dash_pressed",false) and hp>0:
				idle();hurt_stage=0;velocity=Vector2(0,-float(data.stats.jumpPower));damping.y=1;invulnerability=20;return
			if hurt_frames<=0 and not in_air():
				hurt_stage=4;hurt_frames=15;damping.x=2;set_pose("击飞_倒");world.add_visual("hit_floor_low",pos,facing)
		4:
			if hurt_frames<=0:
				if hp<=0: hurt_stage=0;return
				hurt_stage=5;set_pose("击飞_起");hurt_frames=maxi(1,end_frame(action)-frame)
		5:
			if frame<end_frame(action): frame+=1
			if hurt_frames<=0: hurt_stage=0;hurt_damage=0;idle()

func run_events():
	for sound in data.get("sounds",{}).get(str(frame),[]):
		world.voice_events.append({"character":id,"sound":sound,"full":data.has("asset_base")})
	if data.has("program"):
		BVNTimelineVM.run(data.program.get(str(frame),[]),self,script_state)
		return
	for event in data.events.get(str(frame), []):
		if event.get("conditional",false):
			if event.method == "gotoAndPlay" and not just_hits.has("bs1"): play(event.args[0])
			continue
		controller_call(event.controller,event.method,event.args)

func arg(args: Array,index: int,fallback = 0):
	return args[index] if args.size()>index else fallback

func controller_call(controller: String, method: String, args: Array):
	if controller=="effect":
		match method:
			"bisha":
				world.effects.append({"kind":"super","owner":self,"time":10000,"age":0,"focus":arg(args,0,false),"face":arg(args,1,"")})
				world.add_visual("bisha_super" if arg(args,0,false) else "bisha",pos+Vector2(0,-50),facing)
			"shine": flash=3
			"shake", "startShake": world.shake=5
			"endShake": world.shake=0
			"playSoundHit1", "playSoundHit2": world.voice_events.append({"character":"","sound":{"file":"audio/se_hit2.mp3" if method=="playSoundHit2" else "audio/se_hit1.mp3","start":0,"end":0,"stop":false}})
			"slowDown": world.slow_frames=15
			"shadow": script_state.shadow=args
			"endShadow": script_state.erase("shadow")
			"startWanKai":
				world.effects.append({"kind":"super","owner":self,"time":10000,"age":0,"focus":true,"face":arg(args,0,"")})
				world.add_visual("bisha_super",pos+Vector2(0,-50),facing)
			"endBisha", "endWanKai":
				for e in world.effects.duplicate():
					if e.kind=="super" and e.owner==self: world.effects.erase(e)
			"dash": world.add_visual("dash_air" if in_air() else "dash",pos,facing)
			"jump": world.add_visual("jump_air" if jumps>1 else "jump",pos,facing)
			"touchFloor": world.add_visual("touch_floor",pos,facing)
			"walk": world.voice_events.append({"character":"","sound":{"file":"audio/se_step"+str(randi_range(1,3))+".mp3","start":0,"end":0,"stop":false}})
			_: world.unsupported_events[controller+"."+method]=true
		return null
	if SET_ACTIONS.has(method):
		var key: String = SET_ACTIONS[method]
		allowed[key]=arg(args,0,DEFAULT_ACTIONS[key])
		return null
	match method:
		"idle": idle()
		"loop", "gotoAndPlay", "gotoAndStop":
			var label: String = str(arg(args,0,"站立"))
			if data.labels.has(label):
				action=label
				frame=int(data.labels[label])
				stopped=method=="gotoAndStop"
		"endAct":
			allowed.clear()
			steel=false
			move_target.clear()
		"stop": stopped=true
		"move", "movePercent":
			var factor: float = float(data.stats.speed) if method=="movePercent" else 1.0
			velocity=Vector2(float(arg(args,0))*factor*facing,float(arg(args,1))*factor)
		"damping", "dampingPercent":
			var factor: float = float(data.stats.speed) if method=="dampingPercent" else 1.0
			damping=Vector2(float(arg(args,0))*factor,float(arg(args,1))*factor)
		"stopMove": velocity=Vector2.ZERO
		"dash":
			velocity=Vector2(float(data.stats.speed)*float(arg(args,0,3))*facing,0)
			invulnerability=10
		"dashStop": damping.x=absf(velocity.x)*0.5
		"setJump": allowed.jump=arg(args,0,"跳")
		"setDash": allowed.dash=arg(args,0,"瞬步")
		"setAllAct": reset_allowed()
		"setAirMove": air_move=arg(args,0,true)
		"setSteelBody":
			steel=arg(args,0,true)
			super_steel=arg(args,1,false)
		"isApplyG": apply_gravity=arg(args,0,true)
		"addQi": qi=clampf(qi+float(arg(args,0)),0,300)
		"setTouchFloor": floor_action=str(arg(args,0,"落地"))
		"setHitTarget":
			hit_check=str(arg(args,0,""))
			hit_action=str(arg(args,1,""))
		"justHitToPlay":
			if just_hits.has(arg(args,0)): controller_call("mc","gotoAndPlay",[arg(args,1)])
			elif arg(args,2,false): idle()
		"fire", "addAttacker": world.spawn(self,str(arg(args,0)),arg(args,1,{}) if arg(args,1)!=null else {},method=="addAttacker")
		"getAttacker":
			for p in world.projectiles:
				if p.owner==self and p.name==arg(args,0): return p
			return null
		"moveToTarget":
			var other=world.opponent(self)
			if arg(args,0,null)!=null: pos.x=other.pos.x+float(args[0])*facing
			if arg(args,1,null)!=null: pos.y=other.pos.y+float(args[1])
			if arg(args,2,true): facing=1 if other.pos.x>pos.x else -1
		"moveOnce": pos+=Vector2(float(arg(args,0))*facing,float(arg(args,1)))
		"moveTarget": move_target=arg(args,0,{}) if arg(args,0)!=null else {}
		"hurtFly":
			velocity=Vector2(float(arg(args,0))*facing,float(arg(args,1)))
			mode=HURT
			stun=20
		"addHpLosePercent": hp=minf(max_hp,hp+(max_hp-hp)*float(arg(args,0)))
		"addHpPercent": hp=clampf(hp+max_hp*float(arg(args,0)),0,max_hp)
		"addHp": hp=clampf(hp+float(arg(args,0)),0,max_hp)
		"loseHp": hp=maxf(1,hp-float(arg(args,0)))
		"doWanKai": world.transform_fighter(self,int(arg(args,0)))
		"setDirectToTarget": facing=1 if world.opponent(self).pos.x>pos.x else -1
		"setDirectReverse": facing=-facing
		"setCross": is_cross=arg(args,0,true)
		"getSelf", "getDisplay": return self
		"getMcCtrl": return {"controller":"mc","host":self}
		"getCurAction": return action
		"getAction":
			var out := {}
			for key in BVNAI.ACTION_KEYS: out[key]=allowed.has(BVNAI.ACTION_KEYS[key]) and data.labels.has(allowed[BVNAI.ACTION_KEYS[key]]) and (key.ends_with("AIR")==in_air())
			return out
		"getTargets": return [world.opponent(self)]+world.projectiles.filter(func(p):return p.owner!=self)
		"addFunc": script_state.custom_func=args[0].get("script_method","") if args.size()>0 and args[0] is Dictionary else ""
		"getTargetState": return world.opponent(self).action_state()
		"getTargetSP", "getCurrentTarget": return world.opponent(self)
		"getHitVO": return data.actions.get(str(arg(args,0)),{})
		"addChild": return arg(args,0)
		"setTargetVelocity": world.opponent(self).velocity=Vector2(float(arg(args,0)),float(arg(args,1)))
		"setTargetDamping": world.opponent(self).damping=Vector2(float(arg(args,0)),float(arg(args,1)))
		"justHit": return just_hits.has(str(arg(args,0)))
		"targetInRange":
			var distance: Vector2 = world.opponent(self).pos-pos
			distance.x*=facing
			var rx=arg(args,0,null)
			var ry=arg(args,1,null)
			return (rx==null or distance.x>=rx[0] and distance.x<=rx[1]) and (ry==null or distance.y>=ry[0] and distance.y<=ry[1])
		"setHurtAction": hurt_action=str(arg(args,0,""))
		"play": stopped=false
		_: world.unsupported_events[controller+"."+method]=true
	return null

func action_state() -> int:
	if mode==KO: return 30
	if mode==HURT: return 23 if hurt_stage==4 else (24 if hurt_stage==3 else (22 if hurt_stage>0 else 21))
	if guarding: return 20
	if mode==FREE: return 14 if in_air() else 0
	if action.begins_with("万解"): return 50
	if action=="开场": return 60
	if action=="瞬步": return 15
	if action=="胜利": return 61
	if action=="失败": return 62
	if allowed.is_empty() and action.find("必杀")<0: return 40
	if action=="超必杀": return 13
	if action.find("必杀")>=0: return 12
	return 11 if action.find("招")>=0 or action.find("技")>=0 else 10

func collision_data() -> Dictionary:
	return data.collisions[clampi(frame-1,0,data.collisions.size()-1)]

func world_rect(values: Array) -> Rect2:
	var x: float = values[0] if facing > 0 else -values[0]-values[2]
	return Rect2(pos+Vector2(x,values[1]),Vector2(values[2],values[3]))

func hurtbox() -> Rect2:
	return world_rect(collision_data().body)

func receive_hit(hit: Dictionary, source, hit_direction: int) -> bool:
	if hp <= 0 or invulnerability > 0:
		return false
	var power := float(hit.power)
	var attacker = source.owner if source is Dictionary else source
	if attacker is BVNFighter: power*=attacker.attack_rate
	if attacker is BVNFighter and attacker.buff_state.has("attackUp"): power*=1+float(attacker.buff_state.attackUp.value)
	if buff_state.has("defenseUp"): power*=maxf(0,1-float(buff_state.defenseUp.value))
	var blocked: bool = guarding and not hit.get("isBreakDef",false) and (source.pos.x-pos.x)*facing >= 0
	qi = minf(300, qi + minf(20,power*0.085))
	last_damage=power
	last_hit_bisha=attacker.action.find("必杀")>=0 or source is Dictionary and source.name.find("bs")>=0
	if blocked:
		hp -= power*0.05
		energy = maxf(0,energy-power*0.2)
		energy_cooldown=24
		velocity.x = hit_direction * 2
		world.sound_events.append("guard")
		if energy <= 0:
			guarding = false
			mode = HURT
			stun = 21
			set_pose("被打")
	else:
		hp -= power * (0.3 if super_steel else (0.65 if steel else 1.0))
		flash = 3
		world.sound_events.append("hit")
		if not steel:
			guarding = false
			mode = HURT
			stun = maxi(4,roundi(float(hit.get("hurtTime",300))*0.03)+3)
			hurt_damage+=power
			hurt_stage=1 if int(hit.get("hurtType",0))==1 else 0
			hurt_frames=15
			hurt_min_y=pos.y
			hurt_heavy=float(hit.hity)>5
			velocity = Vector2(float(hit.hitx)*hit_direction,float(hit.hity))
			if velocity.y<=0 and in_air(): velocity.y-=3
			elif velocity.y<0: velocity.y-=6
			damping = Vector2(0 if hurt_stage>0 else 0.1,0.5)
			apply_gravity = hit.get("isApplyG",true) if hurt_stage==0 else true
			set_pose("被打")
			allowed.clear()
	invulnerability = 4 if not steel or int(hit.get("hurtType",0))==0 else 10
	hp = maxf(0,hp)
	if hp <= 0:
		mode = KO
		if hurt_stage==0: hurt_stage=4;hurt_frames=15;set_pose("击飞_倒")
	return true
