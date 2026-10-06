extends Node2D

const Fighter = preload("res://scripts/fighter.gd")
const Battle = preload("res://scripts/battle.gd")
var roster: Array = []
var battle
var textures: Dictionary = {}
var bg: Texture2D
var foreground: Texture2D
var font: SystemFont
var large_font: SystemFont
var screen := "menu"
var cpu := true
var player_character := 0
var paused := false
var show_help := false
var show_boxes := false
var mute := false
var voices: Array = []
var tinted_textures: Dictionary = {}
var camera := Vector2(500,235)
var zoom := 1.5
var intro := 60
var pending: Array = [{},{}]
var buttons: Array = []
var music: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var menu_root: Control
var draw_tick := 0
var original_ui: BVNOriginalUI
var difficulty := 2
var round_time := 90
var watch := false
var training_mode := false
var selected_map := "KonohaMura"
var map_data: Dictionary = {}
var match_state: BVNMatch
var end_tick := 0
var round_recorded := false
var camera_scroll := Vector2.ZERO
var options := {"AI_level":3,"keyInputMode":0,"fighterHP":1.0,"fightTime":90,"soundVolume":0.7,"bgmVolume":0.5,"quality":"high"}
var keymaps: Array = KEYMAPS.duplicate(true)
var ai_rng := RandomNumberGenerator.new()
var ai_controllers: Array = []
const KEYMAPS = [{"left":[KEY_A],"right":[KEY_D],"up":[KEY_W],"down":[KEY_S],"attack":[KEY_J],"jump":[KEY_K],"dash":[KEY_L],"skill":[KEY_U],"super":[KEY_I],"assist":[KEY_O],"transform":[KEY_H]}, {"left":[KEY_LEFT],"right":[KEY_RIGHT],"up":[KEY_UP],"down":[KEY_DOWN],"attack":[KEY_KP_1,KEY_1],"jump":[KEY_KP_2,KEY_2],"dash":[KEY_KP_3,KEY_3],"skill":[KEY_KP_4,KEY_4],"super":[KEY_KP_5,KEY_5],"assist":[KEY_KP_6,KEY_6],"transform":[KEY_0,KEY_KP_0]}]

func _ready():
	mute = DisplayServer.get_name() == "headless"
	font = SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC","Noto Sans CJK SC","Arial"])
	large_font = SystemFont.new()
	large_font.font_names = PackedStringArray(["Arial Black","PingFang SC"])
	bg = load("res://assets/stage/bg/0001.png")
	foreground = load("res://assets/stage/map/0001.png")
	for character in ["ichigo","naruto"]:
		var file := FileAccess.open("res://assets/full/fighter/"+character+".json",FileAccess.READ)
		roster.append(JSON.parse_string(file.get_as_text()))
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/bgm.mp3")
	music.volume_db = -20
	add_child(music)
	music.stream.loop = true
	hit_audio = AudioStreamPlayer.new()
	hit_audio.volume_db = -12
	add_child(hit_audio)
	ai_rng.seed = 340
	var layer := CanvasLayer.new()
	add_child(layer)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(menu_root)
	for additive in [false,true]:
		var view := BVNEffectView.new()
		view.game=self
		view.additive=additive
		if additive:
			var material := CanvasItemMaterial.new()
			material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
			view.material=material
		add_child(view)
	original_ui=BVNOriginalUI.new()
	original_ui.setup(self)
	add_child(original_ui)
	var config := ConfigFile.new()
	if config.load("user://settings.cfg")==OK:
		for option in options: options[option]=config.get_value("options",option,options[option])
		for side in range(2):
			for action in keymaps[side]: keymaps[side][action]=config.get_value("keys"+str(side),action,keymaps[side][action])
		difficulty=int(options.AI_level)
		round_time=int(options.fightTime)
		mute=bool(config.get_value("game","mute",mute))
	build_menu()
	if "--battle" in OS.get_cmdline_user_args(): start_battle(false)
	if "--training" in OS.get_cmdline_user_args(): start_battle(true)

func button(text: String, point: Vector2, size: Vector2, callback: Callable):
	var b := Button.new()
	b.text = text
	b.position = point
	b.size = size
	b.add_theme_font_override("font",font)
	b.add_theme_font_size_override("font_size",19)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111b2b")
	style.border_color = Color("d6b369")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_right = 3
	b.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate()
	hover.bg_color = Color("344a63")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_color_override("font_color",Color("fff1cf"))
	b.pressed.connect(callback)
	menu_root.add_child(b)
	buttons.append(b)

func clear_buttons():
	for b in buttons: b.queue_free()
	buttons.clear()

func build_menu():
	clear_buttons()
	screen="menu"
	if original_ui:
		original_ui.submenu=-1
		original_ui.confirm_title=false
		original_ui.continuing=false
	paused=false
	show_help=false
	play_music("op")
	queue_redraw()

func start_battle(training: bool):
	clear_buttons()
	for ai in ai_controllers: ai.dispose()
	ai_controllers.clear()
	if battle: battle.dispose()
	battle = Battle.new(roster[player_character],roster[1-player_character])
	battle.training = training
	if training:
		for fighter in battle.fighters: fighter.qi = 300
	screen = "battle"
	intro = 85
	end_tick=0
	round_recorded=false
	paused = false
	show_help = false
	pending = [{},{}]
	camera = Vector2(513,235)
	zoom = 2.0
	if match_state:
		match_state.score_rate=1 if int(options.keyInputMode)==0 else 0.8
		match_state.apply(battle,float(options.fighterHP),int(options.fightTime))
	if original_ui: original_ui.reset_battle_ui()
	apply_map()
	battle.combat_enabled=false
	for f in battle.fighters:
		if f.data.labels.has("开场"): f.play("开场")
	for i in range(2): ai_controllers.append(BVNAI.new(battle.fighters[i],int(options.AI_level),340+i))

func _input(event: InputEvent):
	if original_ui and original_ui.input_event(event): return
	if not event is InputEventKey: return
	if event.echo: return
	if event.pressed:
		for i in range(2):
			for action in keymaps[i]:
				if event.physical_keycode in keymaps[i][action]: pending[i][action+"_pressed"] = true
		match event.physical_keycode:
			KEY_ESCAPE:
				if screen == "battle": paused = not paused;pause_menu()
			KEY_R:
				if screen == "battle": start_match_round()
			KEY_TAB: show_help = not show_help
			KEY_F3: show_boxes = not show_boxes
			KEY_M:
				mute = not mute
				music.stream_paused = mute
				for voice in voices:
					if is_instance_valid(voice): voice.stream_paused = mute

func pause_menu():
	clear_buttons()
	original_ui.pause_index=3

func start_match_round():
	if match_state:
		roster=[original_ui.load_fighter(match_state.fighter_id(0)),original_ui.load_fighter(match_state.fighter_id(1))]
		player_character=0
	start_battle(training_mode)
	battle.assist_ids=original_ui.assists.duplicate()
	if match_state and match_state.arcade: battle.assist_ids[1]=match_state.mission.assister

func finish_match_round():
	if match_state==null: return
	match_state.finish_round(battle)
	if not match_state.complete: start_match_round();return
	if match_state.arcade:
		original_ui.result_tick=0
		original_ui.result_say=""
		original_ui.result_phase="continue";original_ui.result_choice=0
		screen="winner" if match_state.winner_side==0 else "continue"
		if screen=="winner":
			music.stop();play_ui_sound("win")
			get_tree().create_timer(6.5).timeout.connect(func():
				if screen=="winner": play_music("winloop"))
		else: play_music("continue")
	else: original_ui.begin_select()

func play_ui_sound(name: String):
	if mute: return
	play_voice({"character":"", "sound":{"file":"audio/"+name+".mp3","start":0,"end":0,"stop":false}})

func play_music(name: String):
	var path: String = "res://assets/audio/bgm/"+name.get_file()
	if not path.ends_with(".mp3"): path+=".mp3"
	if not ResourceLoader.exists(path): return
	var stream: AudioStream = load(path)
	if music.stream!=stream: music.stop();music.stream=stream
	if stream is AudioStreamMP3: stream.loop=true
	music.volume_db=linear_to_db(maxf(0.0001,float(options.bgmVolume)))
	if not mute and not music.playing: music.play()

func collect_input(side: int) -> Dictionary:
	var result: Dictionary = pending[side].duplicate()
	pending[side].clear()
	for action in keymaps[side]:
		result[action] = false
		for key in keymaps[side][action]:
			if Input.is_physical_key_pressed(key): result[action] = true
	if int(options.keyInputMode)==1:
		for action in ["attack","jump","dash","skill","super"]:
			if result.get(action,false): result[action+"_pressed"]=true
	return result

func ai_input() -> Dictionary:
	return ai_input_for(1)

func ai_input_for(side: int) -> Dictionary:
	if ai_controllers.size()!=2 or ai_controllers[side].world!=battle:
		for ai in ai_controllers: ai.dispose()
		ai_controllers.clear()
		for i in range(2): ai_controllers.append(BVNAI.new(battle.fighters[i],int(options.AI_level),340+i))
	return ai_controllers[side].decide()

func _physics_process(_delta: float):
	draw_tick += 1
	if screen == "battle" and not paused and not show_help:
		if intro > 0:
			intro -= 1
			battle.tick([{},{}])
			if not mute:
				for event in battle.voice_events: play_voice(event)
			if intro==0:
				battle.combat_enabled=true
				for f in battle.fighters: f.idle()
			pending = [{},{}]
		elif battle.freeze_frames>0:
			battle.freeze_frames-=1
			battle.tick_effects()
		elif not battle.finished:
			var inputs: Array = [{},{}] if battle.effects.any(func(e):return e.kind=="super") else [ai_input_for(0) if watch else collect_input(0),ai_input() if cpu and not battle.training else collect_input(1)]
			battle.tick(inputs)
			if not mute:
				for event in battle.voice_events: play_voice(event)
			if not mute and "swing" in battle.sound_events:
				var sound := "se_hit1"
				hit_audio.stream = load("res://assets/audio/"+sound+".mp3")
				hit_audio.play()
		if battle.finished:
			for f in battle.fighters:
				if f.hp<=0: f.tick({})
				elif f.action=="胜利" and f.frame<f.end_frame("胜利"): f.frame+=1
			end_tick+=1
			if end_tick>=165: finish_match_round()
		if screen=="battle": update_camera()
	queue_redraw()

func update_camera():
	var a: Vector2 = battle.fighters[0].pos
	var b: Vector2 = battle.fighters[1].pos
	var focus: Array = battle.effects.filter(func(e):return e.kind=="super" and e.get("focus",false))
	if not focus.is_empty(): a=focus[0].owner.pos;b=a
	var distance := (a-b).abs()
	var target_zoom := clampf(minf(640/maxf(1,distance.x),480/maxf(1,distance.y)),1,2.5)
	var target := (a+b)*0.5-Vector2(400,300)/target_zoom-Vector2(0,600-battle.floor_y)
	target.x=clampf(target.x,0,maxf(0,battle.width-800/target_zoom))
	target.y=clampf(target.y,-1000*target_zoom,600-600/target_zoom)
	zoom=lerpf(zoom,target_zoom,0.36)
	camera_scroll=camera_scroll.lerp(target,0.36)
	camera=camera_scroll+Vector2(400,300)/zoom

func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func sprite_frame(character: String, info, point: Vector2, facing: int, tint := Color.WHITE, prefix := "", linear := Transform2D.IDENTITY):
	if info == null: return
	var path: String = "res://assets/full/"+prefix+info.file if prefix.begins_with("fighter/") or prefix.begins_with("assist/") else "res://assets/"+character+"/"+prefix+info.file
	var tex := texture(path)
	var transform := Transform2D(0,Vector2(facing,1),0,point)
	draw_set_transform_matrix(world_transform()*transform*linear)
	draw_texture(tex,Vector2(info.offset[0],info.offset[1]),tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func world_transform() -> Transform2D:
	var jitter := Vector2.ZERO
	if battle.shake > 0: jitter = Vector2(sin(draw_tick*3)*battle.shake,cos(draw_tick*4)*battle.shake*0.4)
	return Transform2D(0,Vector2(zoom,zoom),0,Vector2(400,300)-camera*zoom+jitter)

func world_point(point: Vector2) -> Vector2:
	return world_transform()*point

func label_text(text: String, point: Vector2, size: int, color := Color.WHITE, centered := false):
	var x: float = point.x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5 if centered else point.x
	draw_string(font,Vector2(x,point.y+2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0,0,0,0.85))
	draw_string(font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw():
	draw_rect(Rect2(0,0,800,600),Color("101b2a"))
	if bg: draw_texture_rect(bg,Rect2(0,0,800,600),false)
	if screen != "battle": return
	var wt := world_transform()
	draw_set_transform_matrix(wt)
	if map_data.is_empty():
		draw_texture(foreground,Vector2(0,174))
		draw_rect(Rect2(0,396,1000,250),Color("ffe8b1"))
	else:
		draw_map_layer("map",wt)
	for e in battle.effects:
		if e.kind=="super":
			draw_set_transform_matrix(Transform2D.IDENTITY)
			draw_rect(Rect2(0,0,800,600),Color.BLACK)
			draw_set_transform_matrix(wt)
			break
	for trail in battle.shadows:
		var path: String = trail.path
		var key: String = path+str(trail.color)
		if not tinted_textures.has(key):
			var image: Image = texture(path).get_image()
			if image.is_compressed(): image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			var bytes: PackedByteArray = image.get_data()
			for pixel in range(0,bytes.size(),4):
				for channel in range(mini(3,trail.color.size())): bytes[pixel+channel]=clampi(int(bytes[pixel+channel])+int(trail.color[channel]),0,255)
			tinted_textures[key]=ImageTexture.create_from_image(Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes))
		draw_set_transform_matrix(wt*Transform2D(0,Vector2(trail.direct,1),0,trail.pos))
		draw_texture(tinted_textures[key],Vector2(trail.offset[0],trail.offset[1]),Color(1,1,1,trail.alpha))
		draw_set_transform_matrix(wt)
	for f in battle.fighters:
		draw_ellipse_shadow(f.pos+Vector2(0,24),18,4)
	for f in battle.fighters:
		var info = f.data.frames[clampi(f.frame-1,0,f.data.frames.size()-1)]
		if not f.visible: continue
		if f.action == "站立": info = f.data.idle[battle.tick_count%f.data.idle.size()]
		sprite_frame(f.id,info,f.pos,f.facing,Color(1.6,1.6,1.6) if f.flash > 0 else Color.WHITE,f.data.get("idle_base","idle/") if f.action == "站立" else f.data.get("asset_base",""))
		draw_set_transform_matrix(wt)
	for projectile in battle.projectiles:
		var info = projectile.sprite.frames[clampi(projectile.frame,0,projectile.sprite.frames.size()-1)]
		var m: Array = projectile.sprite.matrix
		var linear := Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),Vector2.ZERO)
		sprite_frame(projectile.owner.id,info,projectile.pos,projectile.facing,Color.WHITE,projectile.sprite.get("asset_base","spawn/"+projectile.name+"/"),linear)
		draw_set_transform_matrix(wt)
	if not map_data.is_empty():
		draw_map_layer("front",wt)
		draw_map_layer("front_fix",wt)
	if show_boxes:
		for f in battle.fighters:
			draw_rect(f.hurtbox(),Color(0.2,1,0.2,0.25))
			for hit in f.collision_data().hits: draw_rect(f.world_rect(hit.rect),Color(1,0.2,0.2,0.25))
		for p in battle.projectiles:
			for hit in p.sprite.collisions[clampi(p.frame,0,p.sprite.collisions.size()-1)]: draw_rect(battle.projectile_rect(p,hit.rect),Color(1,0.3,0,0.4))
	draw_set_transform_matrix(Transform2D.IDENTITY)

func draw_ellipse_shadow(point: Vector2, rx: float, ry: float):
	var points := PackedVector2Array()
	for i in range(32): points.append(point+Vector2(cos(i*TAU/32)*rx,sin(i*TAU/32)*ry))
	draw_colored_polygon(points,Color(0,0,0,0.28))

func draw_hud():
	draw_rect(Rect2(0,0,800,108),Color(0.03,0.06,0.1,0.83))
	for i in range(2):
		var f = battle.fighters[i]
		var x := 30.0 if i == 0 else 455.0
		label_text(("P1   " if i == 0 else ("CPU   " if cpu and not battle.training else "P2   "))+f.data.name,Vector2(x,28),20,Color("fff0ce"))
		draw_rect(Rect2(x-2,37,319,24),Color("c6a56d"))
		draw_rect(Rect2(x,39,315,20),Color("3d1722"))
		var w: float = 315*f.hp/1000
		draw_rect(Rect2(x if i == 0 else x+315-w,39,w,20),Color("e67e38") if f.hp<300 else Color("d6d982"))
		label_text(str(int(f.hp)),Vector2(x+157,55),14,Color("1a202a"),true)
		for n in range(3):
			draw_rect(Rect2(x+n*106,66,103,9),Color("18364a"))
			draw_rect(Rect2(x+n*106,66,103*clampf((f.qi-n*100)/100,0,1),9),Color("3bc6ef"))
		draw_rect(Rect2(x,81,315,4),Color("18364a"))
		draw_rect(Rect2(x,81,315*f.energy/100,4),Color("caa86e"))
		if battle.combo[i] > 1: label_text(str(battle.combo[i])+" HIT",Vector2(x,137),24,Color("ffe596"))
	label_text("∞" if battle.training else str(ceili(battle.time_left)),Vector2(400,57),33,Color("ffe4a7"),true)
	label_text("TRAINING" if battle.training else "ROUND 1",Vector2(400,89),12,Color("a4b8c8"),true)
	draw_rect(Rect2(0,567,800,33),Color(0.025,0.045,0.07,0.93))
	label_text("P1  WASD · J 攻击 · K 跳 · L 冲刺 · U 招式 · I 必杀",Vector2(18,589),13,Color("d6e3eb"))
	label_text("Tab 招式表   Esc 暂停",Vector2(590,589),13,Color("f0c77f"))

func _exit_tree():
	for ai in ai_controllers: ai.dispose()
	ai_controllers.clear()
	if battle: battle.dispose()
	if music:
		music.stop()
		music.stream = null
	if hit_audio:
		hit_audio.stop()
		hit_audio.stream = null
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null

func play_voice(event: Dictionary):
	var path: String = "res://assets/full/"+event.sound.file if event.get("full",false) else "res://assets/"+(event.character+"/" if event.character!="" else "")+event.sound.file
	if event.sound.stop:
		for voice in voices.duplicate():
			if is_instance_valid(voice) and voice.get_meta("source","")==path: voice.stop();voices.erase(voice);voice.queue_free()
		return
	if not ResourceLoader.exists(path): return
	var player := AudioStreamPlayer.new()
	player.set_meta("source",path)
	player.stream = load(path)
	player.volume_db = linear_to_db(maxf(0.0001,float(options.soundVolume)))
	add_child(player)
	voices.append(player)
	player.finished.connect(func(): voices.erase(player);player.queue_free())
	player.play(event.sound.start)
	if float(event.sound.get("end",0))>float(event.sound.start):
		get_tree().create_timer(float(event.sound.end)-float(event.sound.start)).timeout.connect(func():
			if is_instance_valid(player): player.stop();voices.erase(player);player.queue_free())

func apply_map():
	var path: String = "res://assets/maps/"+selected_map+"/map.json"
	if not FileAccess.file_exists(path): return
	map_data=JSON.parse_string(FileAccess.get_file_as_string(path))
	battle.width=float(map_data.get("width",1000))
	battle.floor_y=float(map_data.get("floor",365))
	battle.platforms=map_data.platforms
	for i in range(2):
		var p: Array = map_data["p"+str(i+1)]
		battle.fighters[i].pos=Vector2(p[0],p[1])
		battle.fighters[i].ground_y=float(p[1])
	bg=texture("res://assets/maps/"+selected_map+"/bg/0001.png")
	foreground=texture("res://assets/maps/"+selected_map+"/map/0001.png")
	camera_scroll=Vector2(maxf(0,(battle.fighters[0].pos.x+battle.fighters[1].pos.x)/2-400/zoom),600-600/zoom)
	camera=camera_scroll+Vector2(400,300)/zoom
	play_music(str(map_data.bgm))

func draw_map_layer(layer: String,wt: Transform2D):
	if not map_data.layers.has(layer): return
	var l: Dictionary = map_data.layers[layer]
	var info=l.frames[battle.tick_count%l.frames.size()]
	if info==null: return
	var m: Array = l.matrix
	var point := Vector2(m[4],m[5])
	if layer=="front": point+=Vector2(-camera_scroll.x*zoom*0.1,maxf(0,(600-camera_scroll.y*zoom)*0.1))
	draw_set_transform_matrix(wt*Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),point))
	draw_texture(texture("res://assets/maps/"+selected_map+"/"+layer+"/"+info.file),Vector2(info.offset[0],info.offset[1]))
	draw_set_transform_matrix(wt)
