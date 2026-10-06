class_name BVNMatch
extends RefCounted

# Match rules follow GameCtrler.runNext and GameEndCtrler in the 3.4 source.
var teams: Array = [[],[]]
var active := [0,0]
var wins := [0,0]
var carry: Array = [{},{}]
var team_mode := false
var arcade := false
var training := false
var round_number := 1
var mission_index := 0
var missions: Array = []
var score := 0
var score_rate := 1.0
var complete := false
var winner_side := -1
var mission: Dictionary = {}

func configure(selection: Array,is_team: bool,is_arcade: bool,is_training: bool,comic_type: int):
	teams=selection.duplicate(true)
	team_mode=is_team
	arcade=is_arcade
	training=is_training
	if arcade:
		var all: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/missions.json"))
		for group in all:
			if int(group.comic_type)==comic_type and int(group.mode)==(0 if team_mode else 1): missions=group.stages
		set_mission()

func set_mission():
	mission=missions[mission_index]
	var enemies: Array = Array(str(mission.fighter).split(","))
	teams[1]=enemies if team_mode else [enemies.pick_random()]
	active=[0,0]
	wins=[0,0]
	carry=[{},{}]
	round_number=1
	complete=false

func fighter_id(side: int) -> String:
	return teams[side][active[side]]

func apply(battle: BVNBattle,hp_multiplier: float,round_time: int):
	battle.training=training
	battle.scoring=arcade
	battle.score_rate=score_rate
	battle.time_limit=round_time!=-1
	battle.time_left=round_time
	for side in range(2):
		var f: BVNFighter = battle.fighters[side]
		f.max_hp=1000*hp_multiplier*float(mission.get("hpRate",1) if arcade and side==1 else 1)
		f.hp=f.max_hp
		f.attack_rate=float(mission.get("attackRate",1) if arcade and side==1 else 1)
		if carry[side].has("data"): f.data=carry[side].data;f.id=f.data.id
		f.hp=float(carry[side].get("hp",f.hp))
		f.qi=float(carry[side].get("qi",300 if training else 0))

func finish_round(battle: BVNBattle):
	winner_side=battle.winner_side
	if winner_side>=0: wins[winner_side]+=1
	if arcade:
		score+=battle.score
		if winner_side==0 and battle.fighters[1].hp<=0:
			var points: int = 20000 if battle.fighters[0].hp==battle.fighters[0].max_hp else 3000
			if battle.last_attack_bisha[0]: points+=2000
			score+=int(points*score_rate)
	round_number+=1
	if not team_mode:
		carry=[{},{}]
		complete=wins[0]>=2 or wins[1]>=2
		if complete and arcade and winner_side==0: score+=int(5000*score_rate)
		return
	if winner_side<0:
		var has_next := [active[0]+1<teams[0].size(),active[1]+1<teams[1].size()]
		if not has_next[0] or not has_next[1]:
			complete=has_next[0]!=has_next[1]
			winner_side=0 if has_next[0] else (1 if has_next[1] else -1)
			carry=[{},{}]
			return
	var previous: Array = [battle.fighters[0].data,battle.fighters[1].data]
	carry=[{},{}]
	for side in range(2):
		var f: BVNFighter = battle.fighters[side]
		if side==winner_side:
			var time_rate: float = 1 if not battle.time_limit else battle.time_left/maxf(1,battle.time_left+float(battle.tick_count)/30)
			var heal: float = snappedf(0.165*(time_rate+1),0.01)
			carry[side]={"hp":minf(f.max_hp,f.hp+(f.max_hp-f.hp)*heal),"qi":f.qi,"data":f.data}
		else:
			if active[side]+1<teams[side].size():
				active[side]+=1
				var next: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+fighter_id(side)+".json"))
				carry[side]={"qi":minf(300,f.qi+(100 if int(previous[side].comic_type)==int(next.comic_type) else 0))}
			else:
				complete=true
				if winner_side<0: winner_side=1-side

	if complete and arcade and winner_side==0: score+=int((15000 if active[0]==0 else 5000)*score_rate)

func next_mission() -> bool:
	if mission_index+1>=missions.size(): return false
	mission_index+=1
	set_mission()
	return true
