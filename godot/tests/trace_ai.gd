extends SceneTree
func _init():
 var a: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/ichigo.json"))
 var b: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/fighter/naruto.json"))
 var battle=BVNBattle.new(a,b)
 var ai=BVNAI.new(battle.fighters[1],3,340)
 var actions: Dictionary = {}
 for n in range(3000):
  var keys: Dictionary = ai.decide()
  if keys.has("request_action"): actions[keys.request_action]=int(actions.get(keys.request_action,0))+1
  battle.tick([{},keys])
  if n%300==0: print(n," ",battle.fighters[0].hp," ",battle.fighters[1].pos," ",keys," ",battle.fighters[1].action)
 print("actions ",actions," gaps ",battle.unsupported_events)
 ai.dispose();battle.dispose();quit()
