extends RefCounted
# PixelLab exports are kept on a fixed canvas. Root position and scale are shared
# across frames so a raised boot never drags the whole body or its shadow upward.
const ROOT=Vector2(64,116)
const UNIT=23.0/104.0
# Match the side-view animation's ~10 frame changes/s at normal movement speed.
# Keep all 16 poses; the up/down cycle is deliberately slower, about 1.6 seconds.
const WALK_RATE=0.375
var clips:Dictionary={}
var idle:Dictionary={}

func texture_at(path:String)->Texture2D:
	if ResourceLoader.exists(path):return load(path) as Texture2D
	if not FileAccess.file_exists(path):return null
	var picture:=Image.load_from_file(path)
	return ImageTexture.create_from_image(picture) if picture!=null else null

func _init():
	var manifest_path:="res://assets/refined/hero/pixellab_walk/clips.json"
	if not FileAccess.file_exists(manifest_path):return
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	for direction in ["south","north"]:
		if not manifest.has(direction):continue
		var frames:Array[Texture2D]=[]
		for filename in manifest[direction]:
			var path:String="res://assets/refined/hero/pixellab_walk/"+str(filename)
			var texture:Texture2D=texture_at(path)
			if texture==null or texture.get_size()!=Vector2(128,128):break
			frames.append(texture)
		if frames.size()==manifest[direction].size() and frames.size()>=4:
			clips[direction]=frames
			idle[direction]=texture_at("res://assets/refined/hero/pixellab_walk/reference_%s.png"%direction)

func draw(g:Node2D,stride:float,weight:float)->bool:
	var direction:String="north" if g.facing.y<0 else "south"
	if not clips.has(direction):return false
	var texture:Texture2D=idle[direction]
	if g.moved and weight>.1:
		var count:int=clips[direction].size()
		texture=clips[direction][int(fposmod(stride*WALK_RATE/TAU,1.0)*count)%count]
	preload("res://scripts/actor_motion.gd").shadow(g,g.player)
	var rect:=Rect2(g.player+Vector2(0,4)-ROOT*UNIT,Vector2(128,128)*UNIT)
	g.draw_texture_rect(texture,rect,false,Color(1.4,.65,.6) if g.hurt_time>.86 else Color.WHITE)
	return true
