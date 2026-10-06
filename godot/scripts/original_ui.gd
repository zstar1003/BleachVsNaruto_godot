class_name BVNOriginalUI
extends Node2D

var game
var data: Dictionary
var catalog: Dictionary
var selected := [["ichigo"],["naruto"]]
var assists := ["kon","itachi"]
var cursors := [0,9]
var confirmed := [false,false]
var phase := "char_list"
var map_index := 9
var menu_index := 0
var submenu := -1
var submenu_index := 0
var team := false
var mode := "cpu"
var tick := 0
var tutorial_tick := 0
var hit_regions: Array = []
var hover := -1
var changed_forms: Dictionary = {}
var settings: Array = []
var setting_index := 0
var pause_index := 3
var binding_side := 0
var binding_index := 0
var waiting_key := false
var binding_capture := 0
var temporary_keys: Dictionary = {}
var red_hp := [1.0,1.0]
var last_hp := [1.0,1.0]
var red_delay := [0,0]
var red_down := [false,false]
var last_combo := [0,0]
var combo_frame := [0,0]
var combo_display := [0,0]
var result_tick := 0
var result_phase := "continue"
var result_choice := 0
var continuing := false
var result_say := ""
var confirm_title := false
var dialog_choice := 1
const BIND_ACTIONS = ["up","down","left","right","attack","jump","dash","skill","super","assist"]
const BIND_LABELS = ["UP","DOWN","LEFT","RIGHT","ATTACK","JUMP","DASH","SKILL","SUPER SKILL","SPECIAL"]
const BIND_CN = ["上","下","左","右","攻击","跳跃","冲刺","技能","大招","特殊"]
const ROOT_MENU = ["TEAM PLAY","SINGLE PLAY","OPTION","TRAINING","CREDITS","MORE GAMES"]
const CN_MENU = ["小队模式","单人模式","游戏设置","练习模式","制作组","更多游戏"]
const SUB_MENU = ["ACRADE","VS PEOPLE","VS CPU","WATCH"]

func setup(owner_game):
	game=owner_game
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/manifest.json"))
	settings=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/settings.json"))
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/catalog.json"))

func _physics_process(_delta):
	tick+=1
	if game and game.screen=="howtoplay":
		tutorial_tick+=1
		if tutorial_tick>=1210: begin_select()
	if game and game.screen in ["winner","continue","congratulations"]: result_tick+=1
	if game and game.screen=="continue":
		if result_phase=="continue_yes" and result_tick>=40:
			game.match_state.score=maxi(0,game.match_state.score-10000);continuing=true;begin_select()
		elif result_phase=="continue_no" and result_tick>=37:
			result_phase="gameover";result_tick=0;game.music.stop();game.play_ui_sound("gameover")
	if game and game.screen=="battle" and not game.paused and not game.show_help: update_battle_ui()
	queue_redraw()

func matrix(m: Array) -> Transform2D:
	return Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),Vector2(m[4],m[5]))

func symbol(group: String,cls: String,point := Vector2.ZERO,frame := 1,overrides: Dictionary = {},scale := Vector2.ONE,opacity := 1.0):
	var cid: String = str(data[group].classes.get(cls,cls))
	render_symbol(group,cid,Transform2D(0,scale,0,point),frame,overrides,"",0,opacity)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func render_symbol(group: String,cid: String,transform: Transform2D,frame: int,overrides: Dictionary,path: String,depth: int,opacity := 1.0):
	if depth>30 or not data[group].nodes.has(cid): return
	var own: Dictionary = overrides.get(path,{})
	opacity*=float(own.get("alpha",1))
	frame=int(own.get("frame",frame))
	if own.has("position"): transform.origin=Vector2(own.position[0],own.position[1])
	if own.has("offset"): transform.origin+=Vector2(own.offset[0],own.offset[1])
	if own.get("hidden",false): return
	if own.has("scale"): transform=transform.scaled_local(Vector2(own.scale[0],own.scale[1]))
	if own.has("face"):
		if data.faces.has(own.face):
			draw_set_transform_matrix(transform)
			draw_texture(game.texture("res://assets/ui/"+data.faces[own.face]),Vector2.ZERO,Color(1,1,1,opacity))
		return
	if own.has("map"):
		draw_set_transform_matrix(transform)
		draw_texture(game.texture("res://assets/ui/"+data.maps[map_index].image),Vector2(-2,0),Color(1,1,1,opacity))
		return
	var node: Dictionary = data[group].nodes[cid]
	if node.has("composite"):
		var image=node.composite[clampi(frame-1,0,node.composite.size()-1)]
		if image!=null:
			draw_set_transform_matrix(transform)
			draw_texture(game.texture("res://assets/ui/"+group+"/composite/"+cid+"/"+image.file),Vector2(image.offset[0],image.offset[1]),Color(1,1,1,opacity))
		if not node.has("composite_dynamic"): return
	if node.has("image"):
		if node.image!=null:
			draw_set_transform_matrix(transform)
			draw_texture(game.texture("res://assets/ui/"+group+"/"+cid+"/"+node.image.file),Vector2(node.image.offset[0],node.image.offset[1]),Color(1,1,1,opacity))
		return
	var index: int = clampi(int(own.get("frame",frame))-1,0,node.frames.size()-1)
	for child in node.frames[index]:
		if node.has("composite_dynamic") and child.name not in node.composite_dynamic: continue
		if not child.has("id"): continue
		var child_path: String = path+"/"+child.name if child.name!="" else path+"/#"+child.id
		render_symbol(group,child.id,transform*matrix(child.matrix),1,overrides,child_path,depth+1,opacity*float(child.get("alpha",1)))

func bitmap_text(text: String,point: Vector2,scale := 1.0,center := true,variant := ""):
	var file: String = "font/font1"+variant+".png"
	var font: Dictionary = data.font1
	var x: float = point.x-bitmap_width(text)*scale*0.5 if center else point.x
	var atlas: Texture2D = game.texture("res://assets/ui/"+file)
	for c in text:
		if c==" ": x+=10*scale;continue
		var glyph: Dictionary = font.glyphs.get(str(c.unicode_at(0)),{})
		if glyph.is_empty(): continue
		var area := Rect2(float(glyph.x),float(glyph.y),float(glyph.width),float(glyph.height))
		var y: float = float(glyph.yoffset)-15
		if y<0: area.position.y-=y;area.size.y+=y;y=0
		draw_texture_rect_region(atlas,Rect2(Vector2(x,point.y+y*scale),area.size*scale),area)
		x+=(float(glyph.width)-8)*scale

func _draw():
	if game==null: return
	hit_regions.clear()
	match game.screen:
		"menu": draw_menu()
		"select": draw_select()
		"map":
			symbol("select","stg_select")
			symbol("select","select_map_mc",Vector2(157,150),1,{"/ct":{"map":true}})
			symbol("select","select_map_txt_mc",Vector2(308.5,533))
			label_text(data.maps[map_index].name,Vector2(400,555),14,Color.WHITE,true)
			hit_regions=[{"rect":Rect2(106,245,65,85),"map_step":-1},{"rect":Rect2(635,245,65,85),"map_step":1},{"rect":Rect2(156,169,490,270),"confirm":true}]
		"settings": draw_settings()
		"keys": draw_keys()
		"credits": draw_credits()
		"howtoplay":
			symbol("howtoplay","movie_howtoplay",Vector2.ZERO,mini(1198,tutorial_tick+2))
			if tutorial_tick>=30: hit_regions=[{"rect":Rect2(665,5,130,55),"skip":true}]
		"winner": draw_winner()
		"continue": draw_continue()
		"congratulations": symbol("loading","cover_bgimg");symbol("common_ui","mc_congratulations",Vector2.ZERO,mini(50,result_tick+1))
		"battle":
			draw_hud()
			if game.paused: draw_pause()
			if game.show_help:
				draw_texture_rect(game.texture("res://assets/ui/movelist/movelist.jpg"),Rect2(0,0,800,600),false)
				draw_set_button("BACK","返回",Vector2(350,520),true)
	if confirm_title: draw_confirm()

func bitmap_width(text: String) -> float:
	var width := 0.0
	for c in text:
		if c==" ": width+=10
		else:
			var glyph: Dictionary = data.font1.glyphs.get(str(c.unicode_at(0)),{})
			if not glyph.is_empty(): width+=float(glyph.width)-8
	return width+8

func draw_set_button(text: String,cn: String,point: Vector2,active: bool):
	bitmap_text(text,point,1,false)
	if active:
		draw_line(point+Vector2(0,38),point+Vector2(bitmap_width(text),38),Color("fded65"),1)
		label_text(cn,point+Vector2(bitmap_width(text)-game.font.get_string_size(cn,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x,62),20,Color("fded65"))
		symbol("common_ui","select_arrow_mc",point+Vector2(-35,17))

func draw_settings():
	symbol("setting","stg_set_ui",Vector2.ZERO,tick%6+1)
	var scroll: float = maxf(0,30+setting_index*70-480)
	for i in range(settings.size()):
		var item: Dictionary = settings[i]
		var point := Vector2(100,30+i*70-scroll)
		if point.y< -60 or point.y>590: continue
		draw_set_button(item.txt,item.cn,point,setting_index==i)
		if item.has("options"):
			var index:=option_index(item)
			var x: float = 100+bitmap_width(item.txt)+50
			symbol("setting","txt_arrow_mc",Vector2(x,point.y+17))
			bitmap_text(str(item.options[index].label),Vector2(x+10,point.y),1,false)
			symbol("setting","txt_arrow_mc",Vector2(x+20+bitmap_width(str(item.options[index].label)),point.y+17),1,{},Vector2(-1,1))
			hit_regions.append({"rect":Rect2(x-15,point.y,35,45),"setting":i,"step":-1})
		hit_regions.append({"rect":Rect2(95,point.y,650,45),"setting":i,"step":1})

func option_index(item: Dictionary) -> int:
	for i in range(item.options.size()):
		if BVNTimelineVM.binary("==",item.options[i].value,game.options.get(item.optoinKey)): return i
	return 0

func draw_keys():
	symbol("setting","stg_set_ui",Vector2.ZERO,6)
	symbol("setting","keyset_mc")
	var labels := ["SET ALL","SET DEFAULT","APPLY","CANCEL"]
	var cn := ["设置全部","还原默认按键","应用","取消"]
	for i in range(4):
		draw_set_button(labels[i],cn[i],Vector2(100,30+i*70),binding_index==i)
		hit_regions.append({"rect":Rect2(95,30+i*70,450,55),"bind":i})
	for child in data.setting.nodes["40"].frames[0]:
		var index: int = int(child.name.substr(1))
		var action: String = BIND_ACTIONS[index]
		var text: String = OS.get_keycode_string(temporary_keys.get(action,game.keymaps[binding_side][action])[0]).to_upper()
		var max_width: float = 40 if index<4 else 60
		var scale: float = minf(0.8 if index<4 else 1,max_width/bitmap_width(text))
		var point := Vector2(215.05+float(child.matrix[4]),304.05+float(child.matrix[5]))
		bitmap_text(text,point+Vector2(0,-22*scale+(5 if index<4 else 0)),scale,true,"_black")
	if waiting_key:
		symbol("setting","key_set_dialog_mc",Vector2.ZERO,1,{"/txt":{"hidden":true}})
		bitmap_text("PUSH A KEY FOR",Vector2(400,196.55))
		bitmap_text(BIND_LABELS[binding_capture],Vector2(400,275.55))
		label_text("请按下一个键设置【"+BIND_CN[binding_capture]+"】",Vector2(400,417),20,Color.YELLOW,true)

func draw_pause():
	draw_rect(Rect2(0,0,800,600),Color(0,0,0,0.5))
	var labels := ["GAME TITLE","MOVE LIST","BACK SELECT","CONTINUE"]
	var cn := ["返回标题","出招表","返回选人","继续游戏"]
	for i in range(4):
		draw_set_button(labels[i],cn[i],Vector2(100,50+i*70),pause_index==i)
		hit_regions.append({"rect":Rect2(95,50+i*70,500,55),"pause":i})


func draw_confirm():
	if confirm_title:
		hit_regions.clear()
		draw_rect(Rect2(0,0,800,600),Color(0,0,0,0.3))
		draw_rect(Rect2(0,150,800,300),Color(0,0,0,0.8))
		bitmap_text("BACK TITLE",Vector2(400,168))
		label_text("返回到主菜单？",Vector2(400,310),20,Color.WHITE,true)
		for i in range(2):
			draw_set_button("YES" if i==0 else "NO","是" if i==0 else "否",Vector2(265+i*200,370),dialog_choice==i)
			hit_regions.append({"rect":Rect2(250+i*200,365,160,70),"dialog":i})

func pause_action(index: int):
	match index:
		0: confirm_title=true;dialog_choice=1
		1: game.show_help=true
		2: game.paused=false;begin_select(game.training_mode)
		3: game.paused=false

func draw_credits():
	symbol("loading","cover_bgimg")
	var lines := ["程序：剑jian","人物：剑jian、数字化流天、L、V.临界幻想、Azrael、影、赤炎","辅助：小海、主流","图片：剑jian、数字化流天、社长星","策划：剑jian、数字化流天","贡献：灰原·银","","优化：3.4","版权：5DPLAY 版权所有，3.4 由5DPLAY技术支持"]
	for i in range(lines.size()): label_text(lines[i],Vector2(50,50+i*35),20,Color.YELLOW)
	draw_set_button("BACK","返回",Vector2(100,500),true)

func draw_winner():
	var overrides := {"/scoremc":{"hidden":true},"/txtmc":{"frame":10}}
	var ids: Array = game.match_state.teams[0].duplicate()
	var winner: String = game.battle.fighters[0].id
	ids.erase(winner);ids.push_front(winner)
	for i in range(3):
		overrides["/f"+str(i)]={"hidden":i>=ids.size()}
		if i<ids.size(): overrides["/f"+str(i)]={"face":entry("fighter",ids[i]).get("face",{}).get("win_cls",ids[i]+"_w")}
	symbol("loading","winner_stg_mc",Vector2.ZERO,mini(92,result_tick+1),overrides)
	var cid: String = data.loading.classes.winner_stg_mc
	for child in data.loading.nodes[cid].frames[mini(91,result_tick)]:
		if child.name=="scoremc": bitmap_text("SCORE "+str(game.match_state.score),Vector2(child.matrix[4],child.matrix[5]-22))
	if result_tick>=92:
		if result_say=="":
			var says: Array = game.battle.fighters[0].data.get("says",[])
			if not says.is_empty(): result_say=str(says.pick_random())
		var line := ""
		var y := 72.0
		for c in result_say:
			if c=="\n" or game.font.get_string_size(line+c,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x>548:
				label_text(line,Vector2(406.05,y),18,Color.BLACK,true);y+=23;line=""
			if c!="\n": line+=c
		label_text(line,Vector2(406.05,y),18,Color.BLACK,true)
		hit_regions.append({"rect":Rect2(282,516,260,75),"next":true})
		hit_regions.append({"rect":Rect2(700,530,100,65),"result_exit":true})

func result_action():
	if game.screen=="winner":
		if game.match_state.next_mission():
			game.selected_map=game.match_state.mission.map
			game.start_match_round()
		else: game.screen="congratulations";result_tick=0;game.play_music("congratulation")
	elif game.screen=="continue":
		result_phase="continue_yes" if result_choice==0 else "continue_no";result_tick=0
	else: game.build_menu()

func draw_continue():
	var starts := {"continue":5,"continue_yes":92,"continue_no":55,"gameover":132}
	var ends := {"continue":50,"continue_yes":131,"continue_no":91,"gameover":242}
	var frame: int = mini(ends[result_phase],starts[result_phase]+result_tick)
	symbol("gameover","stg_gameover_mc",Vector2.ZERO,frame)
	if result_phase!="gameover":
		var f=game.battle.fighters[0]
		var info=f.data.frames[clampi(f.frame-1,0,f.data.frames.size()-1)]
		if info:
			draw_set_transform(Vector2(377.9,526.05),0,Vector2(3,3))
			draw_texture(game.texture("res://assets/full/"+f.data.asset_base+info.file),Vector2(info.offset[0],info.offset[1]))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		if result_phase=="continue" and result_tick>=45:
			symbol("common_ui","select_arrow_mc",Vector2(80.75 if result_choice==0 else 614.95,402.85))
			hit_regions=[{"rect":Rect2(65,380,180,100),"result":0},{"rect":Rect2(610,380,180,100),"result":1}]
	else:
		for child in data.gameover.nodes["39"].frames[frame-1]:
			if child.name=="ct_score": bitmap_text("SCORE "+str(game.match_state.score),Vector2(child.matrix[4],child.matrix[5]))
		if frame>=242:
			symbol("common_ui","select_arrow_mc",Vector2(338.25,524.6))
			hit_regions=[{"rect":Rect2(315,510,170,70),"exit":true}]

func draw_menu():
	symbol("title","stg_title",Vector2.ZERO,90,{"/btnct":{"hidden":true}})
	var x := 470.0
	var active_index: int = submenu+1+submenu_index if submenu>=0 and submenu_index>=0 else menu_index+(4 if submenu>=0 and menu_index>submenu else 0)
	var y: float = 100+active_index*(49-80) if submenu>=0 else 100
	for i in range(ROOT_MENU.size()):
		draw_menu_button(ROOT_MENU[i],CN_MENU[i],Vector2(x,y),i,false,menu_index==i and (submenu<0 or submenu_index<0))
		x-=40
		y+=80
		if submenu==i:
			for j in range(4):
				var text: String = ("TEAM " if i==0 else "SINGLE ")+SUB_MENU[j]
				draw_menu_button(text,["闯关模式","2P对战","对战电脑","观战电脑"][j],Vector2(x,y),j,true,submenu_index==j)
				x-=40
				y+=60
	label_text("3.4",Vector2(750,580),18,Color.BLACK)

func draw_menu_button(text: String,cn: String,point: Vector2,index: int,child: bool,active: bool):
	var opened: bool = not child and submenu==index
	if active or opened: symbol("common_ui","mc_wzbtn",point,1,{"/bg":{"frame":2 if child or opened else 1}},Vector2(0.9,0.75) if child else Vector2.ONE)
	bitmap_text(text,point,0.75 if child else 1.0,true,"_child" if child or opened else "")
	if active or opened: label_text(cn,point+Vector2(9 if child else 10,45 if child else 60),14 if child else 18,Color.BLACK)
	hit_regions.append({"rect":Rect2(point-Vector2(200,0),Vector2(400,55 if child else 75)),"index":index,"child":child})

func move_menu(direction: int):
	var items: Array = []
	for i in range(6):
		items.append({"index":i,"child":false})
		if submenu==i:
			for j in range(4): items.append({"index":j,"child":true})
	var active: int = submenu+1+submenu_index if submenu>=0 and submenu_index>=0 else menu_index+(4 if submenu>=0 and menu_index>submenu else 0)
	var next: Dictionary = items[posmod(active+direction,items.size())]
	if next.child: submenu_index=next.index;menu_index=submenu
	else: menu_index=next.index;submenu_index=-1

func begin_select(training := false):
	game.clear_buttons()
	game.screen="select"
	game.cpu=mode!="people"
	game.watch=mode=="watch"
	game.training_mode=training
	game.play_music("select")
	selected=[[],[]]
	confirmed=[false,false]
	cursors=[0,9]
	phase="char_list"
	changed_forms.clear()

func current_id(side: int) -> String:
	var list: Array = data.select_grid[phase]
	var item: Dictionary = list[clampi(cursors[side],0,list.size()-1)]
	return str(changed_forms.get(item.id,item.id))

func entry(kind: String,id: String) -> Dictionary:
	for e in catalog[kind]:
		if e.id==id: return e
	return {}

func draw_select():
	symbol("select","stg_select")
	var list: Array = data.select_grid[phase]
	for i in range(list.size()):
		var item: Dictionary = list[i]
		var id: String = str(changed_forms.get(item.id,item.id))
		var e: Dictionary = entry("fighter" if phase=="char_list" else "assist",id)
		var face: String = e.get("face",{}).get("cls",id)
		var point := Vector2(item.position[0],item.position[1])
		if item.more!="": draw_texture(game.texture("res://assets/ui/select/hidden_glow.png"),point-Vector2(16,16))
		symbol("select","slt_item_mc",point,1,{"/ct":{"face":face}})
		hit_regions.append({"rect":Rect2(point,Vector2(50,50)),"select_index":i})
	for side in range(2):
		if side==1 and mode=="arcade": continue
		var selector: bool = not confirmed[side] and (side==0 or mode=="people" or confirmed[0])
		var item: Dictionary = list[cursors[side]]
		var p := Vector2(item.position[0],item.position[1])
		if selector: symbol("select","select_item_mc",p,1,{"/mc":{"frame":side+1}})
		var cards: Array = selected[side].duplicate()
		if phase=="assist_list" and confirmed[side]: cards.append(assists[side])
		elif selector: cards.append(current_id(side))
		if cards.is_empty(): continue
		var count: int = cards.size()
		for i in range(count):
			var is_assist: bool = phase=="assist_list" and i==count-1 and (selector or confirmed[side])
			var e: Dictionary = entry("assist" if is_assist else "fighter",cards[i])
			var group := "selected_item_p1_mc" if side==0 else "selected_item_p2_mc"
			var previous: int = count-1-i
			var scale: float = 1 if previous==0 else 0.85-(count-3-i)*0.15
			var alpha: float = 1 if previous==0 else 0.7-(count-3-i)*0.3
			var y: float = 520 if previous==0 else 520-(count-1)*20+i*(20-(count-3)*3)
			symbol("select",group,Vector2(10 if side==0 else 535,y),1,{"/ct/ct":{"face":e.get("face",{}).get("big_cls",cards[i]+"_b")}},Vector2(scale,scale),maxf(0.1,alpha))
			if previous==0:
				var name: String = e.get("name",cards[i])
				var x: float = 253-game.font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x if side==0 else 545
				label_text(name,Vector2(x,579),14,Color.WHITE)

func confirm(side: int):
	if confirmed[side]: return
	var id:=current_id(side)
	if id.begins_with("random"):
		var candidates: Array = []
		for e in catalog["fighter" if phase=="char_list" else "assist"]:
			if id=="random" or int(e.comic_type)==(0 if id=="random_bleach" else 1): candidates.append(e.id)
		id=candidates.pick_random()
	if phase=="char_list":
		if id in selected[side]: return
		selected[side].append(id)
		confirmed[side]=selected[side].size()>=(3 if team else 1)
		if not confirmed[side]: move_cursor(side,1 if side==0 else -1,0)
	else:
		assists[side]=id
		confirmed[side]=true
	if mode=="arcade" and confirmed[0]:
		if phase=="char_list":
			selected[1]=[]
			for i in range(3 if team else 1): selected[1].append(catalog.fighter.pick_random().id)
		else: assists[1]=catalog.assist.pick_random().id
		confirmed[1]=true
	if confirmed[0] and confirmed[1]:
		if phase=="char_list":
			phase="assist_list"
			confirmed=[false,false]
			cursors=[0,9]
		else:
			if mode=="arcade": launch_battle()
			else: game.screen="map"

func launch_battle():
	if continuing:
		game.match_state.teams[0]=selected[0].duplicate();game.match_state.set_mission();continuing=false
	else:
		game.match_state=BVNMatch.new()
		game.match_state.configure(selected,team,mode=="arcade",game.training_mode,int(load_fighter(selected[0][0]).comic_type))
	game.selected_map=data.maps[map_index].id
	if game.selected_map=="random": game.selected_map=data.maps.slice(1).pick_random().id
	if mode=="arcade": game.selected_map=game.match_state.mission.map
	game.start_match_round()

func load_fighter(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/"+id+".json"))

func activate_menu(index: int,child: bool):
	if child:
		mode=["arcade","people","cpu","watch"][index]
		team=submenu==0
		if mode=="arcade": game.screen="howtoplay";tutorial_tick=0;game.play_music("back")
		else: begin_select()
	elif index<2:
		submenu=-1 if submenu==index else index
		menu_index=index
		submenu_index=0 if submenu>=0 else -1
	elif index==2: game.screen="settings";setting_index=0
	elif index==3:
		team=false
		mode="cpu"
		begin_select(true)
	elif index==4: game.screen="credits"
	elif index==5: pass # Original 3.4 source leaves MORE GAMES without a callback.

func input_event(event: InputEvent) -> bool:
	if game.screen=="battle" and not game.paused and not game.show_help: return false
	if event is InputEventMouseMotion:
		for h in hit_regions:
			if h.rect.has_point(get_local_mouse_position()):
				if h.has("index"):
					if h.child: submenu_index=h.index
					else: menu_index=h.index;submenu_index=-1
				if h.has("setting"): setting_index=h.setting
				if h.has("pause"): pause_index=h.pause
				if h.has("dialog"): dialog_choice=h.dialog
				if h.has("bind"): binding_index=h.bind
				if h.has("select_index"): cursors[0 if not confirmed[0] else 1]=h.select_index
		return true
	if event is InputEventMouseButton and event.pressed:
		for h in hit_regions:
			if h.rect.has_point(get_local_mouse_position()):
				if h.has("index"): activate_menu(h.index,h.child)
				if h.has("map_step"): map_index=posmod(map_index+h.map_step,data.maps.size())
				if h.has("confirm"): launch_battle()
				if h.has("select_index"):
					var side:=0 if not confirmed[0] else 1
					cursors[side]=h.select_index
					if event.button_index==MOUSE_BUTTON_RIGHT: change_form(side)
					else: confirm(side)
				if h.has("setting"): setting(h.setting,h.get("step",1))
				if h.has("pause"): pause_action(h.pause)
				if h.has("bind"): binding_index=h.bind;bind_key()
				if h.has("skip"): begin_select()
				if h.has("next"): result_action()
				if h.has("result"): result_choice=h.result;result_action()
				if h.has("result_exit"): confirm_title=true;dialog_choice=1
				if h.has("dialog"):
					confirm_title=false
					if h.dialog==0: game.build_menu()
				if h.has("exit"): game.build_menu()
				break
		return true
	if not event is InputEventKey or not event.pressed or event.echo: return true
	var key: int = event.physical_keycode
	if not waiting_key and key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_J,KEY_ENTER]: game.play_ui_sound("menu_confirm" if key in [KEY_J,KEY_ENTER] else "menu_select")
	if waiting_key:
		temporary_keys[BIND_ACTIONS[binding_capture]]=[key]
		binding_capture+=1
		waiting_key=binding_capture<10
		return true
	if confirm_title:
		if key in [KEY_A,KEY_LEFT]: dialog_choice=0
		if key in [KEY_D,KEY_RIGHT]: dialog_choice=1
		if key in [KEY_J,KEY_ENTER,KEY_ESCAPE]:
			confirm_title=false
			if key!=KEY_ESCAPE and dialog_choice==0: game.build_menu()
		return true
	if game.show_help:
		if key in [KEY_ESCAPE,KEY_J,KEY_ENTER,KEY_TAB]: game.show_help=false
		return true
	if game.screen=="battle" and game.paused:
		if key in [KEY_W,KEY_UP]: pause_index=posmod(pause_index-1,4)
		if key in [KEY_S,KEY_DOWN]: pause_index=posmod(pause_index+1,4)
		if key in [KEY_J,KEY_ENTER]: pause_action(pause_index)
		if key==KEY_ESCAPE: game.paused=false
		return true
	if key==KEY_ESCAPE:
		if game.screen=="keys": game.screen="settings"
		elif submenu>=0 and game.screen=="menu": submenu=-1
		else: game.build_menu()
		return true
	match game.screen:
		"menu":
			if key in [KEY_W,KEY_UP]:
				move_menu(-1)
			if key in [KEY_S,KEY_DOWN]:
				move_menu(1)
			if key in [KEY_J,KEY_ENTER,KEY_SPACE]: activate_menu(submenu_index if submenu>=0 and submenu_index>=0 else menu_index,submenu>=0 and submenu_index>=0)
		"select":
			var side:=1 if key in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_1,KEY_KP_1,KEY_5,KEY_KP_5] else 0
			if mode!="people" and confirmed[0]: side=1
			if key in [KEY_W,KEY_UP]: move_cursor(side,0,-1)
			if key in [KEY_S,KEY_DOWN]: move_cursor(side,0,1)
			if key in [KEY_A,KEY_LEFT]: move_cursor(side,-1,0)
			if key in [KEY_D,KEY_RIGHT]: move_cursor(side,1,0)
			if key in [KEY_I,KEY_5,KEY_KP_5]: change_form(side)
			if key in [KEY_J,KEY_ENTER,KEY_1,KEY_KP_1]: confirm(side)
		"map":
			if key in [KEY_A,KEY_LEFT]: map_index=posmod(map_index-1,data.maps.size())
			if key in [KEY_D,KEY_RIGHT]: map_index=posmod(map_index+1,data.maps.size())
			if key in [KEY_J,KEY_ENTER]: launch_battle()
		"settings":
			if key in [KEY_W,KEY_UP]: setting_index=posmod(setting_index-1,settings.size())
			if key in [KEY_S,KEY_DOWN]: setting_index=posmod(setting_index+1,settings.size())
			if key in [KEY_A,KEY_LEFT]: setting(setting_index,-1)
			if key in [KEY_D,KEY_RIGHT]: setting(setting_index,1)
			if key in [KEY_J,KEY_ENTER]: setting(setting_index,1)
		"keys":
			if key in [KEY_W,KEY_UP]: binding_index=posmod(binding_index-1,4)
			if key in [KEY_S,KEY_DOWN]: binding_index=posmod(binding_index+1,4)
			if key in [KEY_J,KEY_ENTER]: bind_key()
		"continue":
			if result_phase=="continue" and result_tick>=45:
				if key in [KEY_A,KEY_LEFT]: result_choice=0
				if key in [KEY_D,KEY_RIGHT]: result_choice=1
				if key in [KEY_J,KEY_ENTER]: result_action()
			elif result_phase=="gameover" and result_tick>=110 and key in [KEY_J,KEY_ENTER]: game.build_menu()
		"winner", "congratulations":
			if key in [KEY_J,KEY_ENTER] and (game.screen!="winner" or result_tick>=92): result_action()
		"howtoplay":
			if tutorial_tick>=30 and key in [KEY_J,KEY_ENTER]: begin_select()
		"credits": game.build_menu()
	return true

func change_form(side: int):
	var item: Dictionary = data.select_grid[phase][cursors[side]]
	if item.more!="": changed_forms[item.id]=item.id if changed_forms.has(item.id) and changed_forms[item.id]==item.more else item.more

func move_cursor(side: int,dx: int,dy: int):
	if confirmed[side]: return
	var list: Array = data.select_grid[phase]
	var item: Dictionary = list[cursors[side]]
	var x: int = item.x
	var y: int = item.y
	var rows:=7 if phase=="char_list" else 6
	for step in range(1,11):
		var tx:=posmod(x+dx*step,10)
		var ty:=posmod(y+dy*step,rows)
		var nearest: int = -1
		var distance:=100
		for i in range(list.size()):
			if dy==0 and int(list[i].x)==tx and int(list[i].y)==y: cursors[side]=i;return
			if dy!=0 and int(list[i].y)==ty and absi(int(list[i].x)-x)<distance: nearest=i;distance=absi(int(list[i].x)-x)
		if nearest>=0: cursors[side]=nearest;return

func bind_key():
	match binding_index:
		0: binding_capture=0;waiting_key=true
		1: temporary_keys=game.KEYMAPS[binding_side].duplicate(true)
		2: game.keymaps[binding_side]=temporary_keys.duplicate(true);game.screen="settings"
		3: game.screen="settings"

func setting(index: int,step := 1):
	var item: Dictionary = settings[index]
	if item.has("options"):
		game.options[item.optoinKey]=item.options[posmod(option_index(item)+step,item.options.size())].value
	elif index<2:
		binding_side=index;binding_index=0;temporary_keys=game.keymaps[index].duplicate(true);game.screen="keys"
	else:
		var config := ConfigFile.new()
		for key in game.options: config.set_value("options",key,game.options[key])
		for side in range(2):
			for action in game.keymaps[side]: config.set_value("keys"+str(side),action,game.keymaps[side][action])
		config.save("user://settings.cfg")
		game.difficulty=int(game.options.AI_level)
		game.round_time=int(game.options.fightTime)
		game.build_menu()

func draw_hud():
	if game.battle==null: return
	var o: Dictionary = {"/hpbarmc":{"frame":25},"/fzqi1":{"frame":15},"/fzqi2":{"frame":15},"/hpbarmc/scoremc":{"hidden":not (game.match_state and game.match_state.arcade)},"/startKOmc":{"hidden":true},"/hits1":{"hidden":true},"/hits2":{"hidden":true}}
	for side in range(2):
		var f=game.battle.fighters[side]
		var n:=str(side+1)
		o["/hpbarmc/bar"+n+"/bar"]={"scale":[f.hp/f.max_hp,1]}
		o["/hpbarmc/bar"+n+"/redbar"]={"scale":[red_hp[side],1]}
		o["/hpbarmc/energy"+n+"/txtmc"]={"frame":int(f.data.comic_type)+1,"scale":[1 if side==0 else -1,1]}
		o["/hpbarmc/energy"+n+"/barmc/bar"]={"scale":[f.energy/100,1]}
		o["/hpbarmc/face"+n+"/face2"]={"hidden":true}
		o["/hpbarmc/face"+n+"/face3"]={"hidden":true}
		o["/hpbarmc/face"+n+"/face/sp"]={"hidden":true}
		o["/hpbarmc/face"+n+"/face/ct"]={"face":f.data.get("face",{}).get("bar_cls",f.id+"_m")}
		o["/fzqi"+n+"/facemc/ct"]={"face":assists[side]}
		o["/fzqi"+n+"/fzqibar/sp"]={"hidden":true}
		o["/fzqi"+n+"/fzqibar/barmc"]={"scale":[1,game.battle.assist_meter[side]/100]}
		o["/fzqi"+n+"/readymc/mc"]={"scale":[1 if side==0 else -1,1]}
		o["/fzqi"+n+"/readymc"]={"hidden":game.battle.assist_meter[side]<100}
		for i in range(1,5):
			o["/fzqi"+n+"/barmc/bar/bar"+str(i)]={"hidden":f.qi<=(i-1)*100 if i<4 else f.qi<300,"scale":[clampf((f.qi-(i-1)*100)/100,0,1) if i<4 else 1,1]}
		o["/fzqi"+n+"/barmc/bar/ghost"]={"hidden":f.qi>=100,"frame":2 if f.qi>60 else 1}
		o["/fzqi"+n+"/barmc/txtmc"]={"frame":mini(4,int(f.qi/100)+1),"scale":[1 if side==0 else -1,1]}
		o["/hpbarmc/win_p"+n+"/w1"]={"frame":2 if game.match_state and game.match_state.wins[side]>=1 else 1}
		o["/hpbarmc/win_p"+n+"/w2"]={"frame":2 if game.match_state and game.match_state.wins[side]>=2 else 1}
	o["/hpbarmc/timemc/wuxian"]={"hidden":not (game.battle.training or not game.battle.time_limit)}
	if game.match_state and game.match_state.team_mode:
		for side in range(2):
			for i in range(1,3):
				var index: int = game.match_state.active[side]+i
				var path: String = "/hpbarmc/face"+str(side+1)+"/face"+str(i+1)
				o[path]={"hidden":index>=game.match_state.teams[side].size()}
				if index<game.match_state.teams[side].size(): o[path+"/ct"]={"face":game.match_state.teams[side][index]+"_m"}
	symbol("fight","ui_fight",Vector2.ZERO,1,o)
	draw_combos()
	if game.match_state and game.match_state.arcade:
		var score := str(game.match_state.score+game.battle.score).pad_zeros(10)
		for i in range(score.length()): symbol("fight","txtmc_score",Vector2(593.3+i*10,10.6),int(score[i])+1)
	draw_bisha_faces()
	if game.intro>0:
		var frame: int = clampi(95-game.intro,10,88)
		var round_number: int = mini(5,game.match_state.round_number if game.match_state else 1)
		var number_start: int = int(data.fight.nodes["196"].labels["r"+str(round_number)])
		symbol("fight","228",Vector2(0,-50),frame,{"/nummc":{"frame":mini(number_start+15,number_start+maxi(0,frame-28))}})
	if game.battle.finished:
		var frame: int = mini(199,145+game.end_tick) if game.battle.time_left>0 or not game.battle.time_limit else mini(266,220+game.end_tick)
		if game.battle.winner_side<0: frame=mini(308,267+game.end_tick)
		if game.end_tick>=60 and game.battle.winner_side>=0:
			frame=mini(210,200+game.end_tick-60)
			var offset_x: float = 30-27.05 if game.battle.winner_side==0 else 546-27.05
			symbol("fight","228",Vector2(0,30),frame,{"/winnermc":{"frame":mini(61,(30 if game.battle.fighters[game.battle.winner_side].hp==game.battle.fighters[game.battle.winner_side].max_hp else 1)+game.end_tick-60),"offset":[offset_x,0.8]}})
		else: symbol("fight","228",Vector2.ZERO,frame)
	if not game.battle.training and game.battle.time_limit:
		var time:=str(ceili(game.battle.time_left)).pad_zeros(2)
		for i in range(2): symbol("fight","time_txtmc",Vector2(378+i*20,30.6),int(time[i])+1)

func reset_battle_ui():
	red_hp=[1.0,1.0];last_hp=[1.0,1.0];red_delay=[0,0];red_down=[false,false]
	last_combo=[0,0];combo_frame=[0,0];combo_display=[0,0]

func update_battle_ui():
	for side in range(2):
		var f=game.battle.fighters[side]
		var rate: float = f.hp/f.max_hp
		if rate!=last_hp[side] and red_delay[side]<=0: red_hp[side]=last_hp[side]
		last_hp[side]=rate
		match f.action_state():
			21,22: red_delay[side]=100
			23,24:
				if not red_down[side]: red_delay[side]=45;red_down[side]=true
				red_delay[side]=maxi(0,red_delay[side]-1)
			_: red_delay[side]=0;red_down[side]=false
		if red_delay[side]<=0: red_hp[side]=rate if absf(rate-red_hp[side])<0.01 else lerpf(red_hp[side],rate,0.1 if rate<red_hp[side] else 0.02)
		var hits: int = game.battle.combo[side]
		if hits!=last_combo[side]:
			if hits>1:
				combo_frame[side]=10 if last_combo[side]<=1 else 30;combo_display[side]=hits
			elif last_combo[side]>1: combo_frame[side]=51
		last_combo[side]=hits
		if combo_frame[side]>0: combo_frame[side]=mini(29 if combo_frame[side]<30 else (50 if combo_frame[side]<51 else 56),combo_frame[side]+1)

func draw_combos():
	for side in range(2):
		if combo_frame[side]==0 or combo_frame[side]>=56: continue
		var text := str(combo_display[side])
		var offset: float = 45-(text.length()*35)
		var point := Vector2(62.15-offset if side==0 else 662.15,121.95)
		symbol("fight","hits_mc",point,combo_frame[side],{"/ct":{"hidden":true}})
		var children: Array = data.fight.nodes["55"].frames[combo_frame[side]-1]
		for child in children:
			if child.name!="ct": continue
			for i in range(text.length()):
				render_symbol("fight","22",Transform2D(0,Vector2.ONE,0,point)*matrix(child.matrix)*Transform2D(0,Vector2.ONE,0,Vector2(offset+i*35,0)),int(text[i])+1,{},"",0)
		draw_set_transform_matrix(Transform2D.IDENTITY)

func draw_bisha_faces():
	var d: Dictionary = game.battle.effect_library.get("symbols",{}).get("bisha_face_mc",{})
	if d.is_empty(): return
	for effect in game.battle.effects:
		if effect.kind!="super": continue
		var owner=effect.owner
		var key: String = str(effect.get("face",""))
		if key=="" or not owner.data.portraits.has(key): continue
		var frame: int = clampi(int(effect.get("age",0))+1,0,68)
		var point := Vector2(0,100+100/game.zoom)
		var info=d.frames[frame]
		if info: draw_texture(game.texture("res://assets/full/"+d.asset_base+info.file),point+Vector2(info.offset[0],info.offset[1]))
		var id: String = "facemc1" if game.battle.fighters.find(owner)==0 else "facemc2"
		if d.faces[frame].has(id):
			var m: Array = d.faces[frame][id]
			draw_set_transform_matrix(Transform2D(0,Vector2.ONE,0,point)*matrix(m))
			draw_texture_rect(game.texture("res://assets/full/"+owner.data.portraits[key]),Rect2(0,0,254,180),false)
			draw_set_transform_matrix(Transform2D.IDENTITY)

func label_text(text: String,point: Vector2,size: int,color := Color.WHITE,centered := false):
	var x: float = point.x-game.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5 if centered else point.x
	draw_string(game.font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
