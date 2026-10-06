class_name BVNEffectView
extends Node2D

var game
var additive := false

func _physics_process(_delta): queue_redraw()

func _draw():
	if game==null or game.screen!="battle" or game.battle==null: return
	for effect in game.battle.effects:
		if effect.kind!="visual" or (effect.get("blend","")=="add")!=additive: continue
		var d: Dictionary = effect.data
		var frame: int = clampi(effect.age,0,d.frames.size()-1)
		var info=d.frames[frame]
		if info==null: continue
		var rotation: float = effect.get("rotation",0)
		draw_set_transform_matrix(game.world_transform()*Transform2D(rotation,Vector2(effect.direct,1),0,effect.pos))
		draw_texture(game.texture("res://assets/full/"+d.asset_base+info.file),Vector2(info.offset[0],info.offset[1]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
