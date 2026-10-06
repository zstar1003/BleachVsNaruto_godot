class_name BVNTimelineVM
extends RefCounted

# A closed AS3 timeline interpreter: only imported expressions and game controllers.
# It has no filesystem, network, eval, or arbitrary native-method bridge.
static func script_methods(env: Dictionary) -> Dictionary:
	return env.projectile.sprite.get("methods",env.host.data.get("methods",{})) if env.projectile!=null else env.host.data.get("methods",{})

static func run(program: Array, host, state: Dictionary, projectile = null):
	var env := {"host":host,"state":state,"locals":{},"projectile":projectile}
	return statements(program,env)

static func run_function(method: String,args: Array,host,state: Dictionary):
	var env := {"host":host,"state":state,"locals":{},"projectile":null}
	return invoke({"scope":"this"},method,args,env)

static func truth(v) -> bool:
	match typeof(v):
		TYPE_NIL: return false
		TYPE_BOOL: return v
		TYPE_INT, TYPE_FLOAT: return v!=0
		TYPE_STRING: return v!=""
	return true

static func statements(items: Array, env: Dictionary):
	for s in items:
		match s[0]:
			"eval": expression(s[1],env)
			"foreach":
				var values=expression(s[2],env)
				if values is Array:
					for value in values:
						assign(s[1],value,env)
						var result=statements(s[3],env)
						if result is Dictionary and result.has("continue"): continue
						if result!=null: return result
			"set":
				env.locals[s[1][1]]=expression(s[2],env)
			"continue": return {"continue":true}
			"return": return {"return":expression(s[1],env)}
			"if":
				var result = statements(s[2] if truth(expression(s[1],env)) else s[3],env)
				if result != null: return result
			"switch":
				var value = expression(s[1],env)
				for c in s[2]:
					if value == expression(c[0],env) or c[2]:
						var result = statements(c[1],env)
						if result != null: return result
						break
	return null

static func expression(n: Array, env: Dictionary):
	match n[0]:
		"lit": return n[1]
		"var":
			match n[1]:
				"this", "parent": return {"scope":n[1]}
				"NaN": return NAN
			return env.locals.get(n[1],env.state.get(n[1],null))
		"new": return {"display_class":str(n[1][1][1])}
		"array":
			var out: Array = []
			for v in n[1]: out.append(expression(v,env))
			return out
		"object":
			var out := {}
			for v in n[1]: out[v[0]]=expression(v[1],env)
			return out
		"get": return property(expression(n[1],env),n[2],env)
		"index": return property(expression(n[1],env),expression(n[2],env),env)
		"un":
			var v = expression(n[2],env)
			match n[1]:
				"!": return not truth(v)
				"-": return -number(v)
				"+": return number(v)
		"ternary": return expression(n[2] if truth(expression(n[1],env)) else n[3],env)
		"bin":
			var a = expression(n[2],env)
			if n[1]=="&&": return expression(n[3],env) if truth(a) else a
			if n[1]=="||": return a if truth(a) else expression(n[3],env)
			return binary(n[1],a,expression(n[3],env))
		"assign":
			var v = expression(n[3],env)
			if n[1]!="=": v=binary(n[1][0],expression(n[2],env),v)
			assign(n[2],v,env)
			return v
		"post":
			var v=number(expression(n[2],env))
			assign(n[2],v+(1 if n[1]=="++" else -1),env)
			return v
		"call":
			var args: Array = []
			for v in n[2]: args.append(expression(v,env))
			var callee: Array = n[1]
			if callee[0]=="get": return invoke(expression(callee[1],env),callee[2],args,env)
			if callee[0]=="var":
				match callee[1]:
					"Boolean": return truth(args[0])
					"Number", "int", "uint": return number(args[0])
					"String": return str(args[0])
				return env.host.controller_call("mc",callee[1],args)
	return null

static func number(v) -> float:
	return float(v) if v!=null and (v is float or v is int or v is bool) else 0.0

static func binary(op: String,a,b):
	match op:
		"is", "as":
			var matches := false
			var type: String = b.get("runtime_type","") if b is Dictionary else ""
			if type=="Array": matches=a is Array
			elif a is Dictionary and a.has("attacker"):
				matches=(type=="Bullet" and not a.attacker) or (type=="Assister" and a.owner.owner_fighter!=null) or (type=="FighterAttacker" and a.attacker and a.owner.owner_fighter==null)
			return matches if op=="is" else (a if matches else null)
		"==", "===", "!=", "!==":
			var same := false
			if typeof(a)==typeof(b): same=a==b
			elif typeof(a) in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT]: same=number(a)==number(b)
			return not same if op in ["!=","!=="] else same
		"<": return number(a)<number(b)
		">": return number(a)>number(b)
		"<=": return number(a)<=number(b)
		">=": return number(a)>=number(b)
		"+": return str(a)+str(b) if a is String or b is String else number(a)+number(b)
		"-": return number(a)-number(b)
		"*": return number(a)*number(b)
		"/": return number(a)/number(b) if number(b)!=0 else 0.0
		"%": return fmod(number(a),number(b)) if number(b)!=0 else 0.0
	return null

static func property(obj,key,env: Dictionary):
	if obj is Dictionary:
		if obj.has("scope"):
			if str(key)=="$assisterCtrler": return {"controller":"assist"}
			if str(key).begins_with("$") and str(key).ends_with("_ctrler"):
				return {"controller":str(key).trim_prefix("$").trim_suffix("_ctrler")}
			if script_methods(env).has(str(key)): return {"script_method":str(key)}
			return env.state.get(str(key),null)
		if obj.has("controller"):
			if key=="effect": return {"controller":"effect"}
			match key:
				"target": return env.host.world.opponent(env.host)
				"owner_fighter_ctrler": return {"controller":"fighter"}
				"owner_mc_ctrler": return {"controller":"mc"}
			return env.host.get(str(key))
		if key=="team" and obj.has("owner"): return {"id":env.host.world.fighters.find(obj.owner.owner_fighter if obj.owner.owner_fighter!=null else obj.owner)}
		if key=="direct" and obj.has("facing"): return obj.facing
		if key=="comicType" and obj.has("comic_type"): return obj.comic_type
		if key=="isAttacking" and obj.has("attacker"): return obj.active
		return obj.get(str(key) if key is float or key is int else key,null)
	if obj is BVNFighter:
		match key:
			"x": return obj.pos.x
			"y": return obj.pos.y
			"hpMax": return obj.max_hp
			"heavy", "speed": return obj.data.stats.get(key,0)
			"direct": return obj.facing
			"team": return {"id":env.host.world.fighters.find(obj.owner_fighter if obj.owner_fighter!=null else obj)}
			"actionState": return obj.action_state()
			"isAlive": return obj.hp>0
			"isApplyG": return obj.apply_gravity
			"isSuperSteelBody": return obj.super_steel
		return obj.get(str(key))
	if obj is Array and key is String and key=="length": return obj.size()
	if obj is Array and key is float or obj is Array and key is int:
		return obj[int(key)] if int(key)>=0 and int(key)<obj.size() else null
	return null

static func assign(target: Array,v,env: Dictionary):
	if target[0]=="var":
		if env.locals.has(target[1]): env.locals[target[1]]=v
		else: env.state[target[1]]=v
	elif target[0]=="index":
		var obj=expression(target[1],env)
		var key=expression(target[2],env)
		if obj is Array and int(key)>=0 and int(key)<obj.size(): obj[int(key)]=v
		elif obj is Dictionary: obj[str(key)]=v
	elif target[0]=="get":
		var obj=expression(target[1],env)
		if obj is Dictionary:
			if obj.has("scope"): env.state[target[2]]=v
			else: obj[target[2]]=v
		elif obj is BVNFighter:
			match target[2]:
				"x": obj.pos.x=number(v)
				"y": obj.pos.y=number(v)
				_: obj.set("apply_gravity" if target[2]=="isApplyG" else target[2],v)

static func invoke(obj,method: String,args: Array,env: Dictionary):
	if obj is Dictionary:
		if obj.has("native"): return env.host.controller_call(obj.native,method,args)
		if obj.has("controller"):
			if obj.controller=="attacker" and env.projectile!=null:
				return env.host.world.attacker_call(env.projectile,method,args)
			if obj.controller=="assist" and env.projectile!=null: return env.host.world.assister_call(env.projectile,method,args)
			return obj.get("host",env.host).controller_call(obj.controller,method,args)
		if obj.has("buff_host"):
			obj.buff_host.buff_state[method]={"value":args[0],"frames":float(args[1])*30}
			return null
		if obj.has("sprite") and obj.has("owner"):
			if method=="isAttacking": return obj.active
			return env.host.world.attacker_call(obj,method,args)
		if obj.has("scope"):
			if script_methods(env).has(method):
				var prior: Dictionary = env.locals
				env.locals={}
				var parameters: Array = (env.projectile.sprite if env.projectile!=null else env.host.data).get("method_parameters",{}).get(method,[])
				for i in range(args.size()): env.locals[parameters[i] if i<parameters.size() else "param"+str(i+1)]=args[i]
				var result=statements(script_methods(env)[method],env)
				env.locals=prior
				return result.get("return") if result is Dictionary else null
			return env.host.controller_call("mc",method,args)
	if obj is Array and method=="indexOf": return obj.find(args[0])
	if obj is BVNFighter:
		match method:
			"getCtrler": return {"controller":"fighter","host":obj}
			"getBuffCtrl": return {"buff_host":obj}
			_: return obj.controller_call("fighter",method,args)
	return null
