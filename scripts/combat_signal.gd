extends RefCounted
var sprites:Array[Sprite2D]=[]
var used:=0
func begin():
	used=0
	for sprite in sprites:sprite.hide()
func draw(g:Node2D,atlas,index:int,rect:Rect2,color:Color,strength:float,solid:bool=false,charge:float=0.0):
	if strength<=0 or g.defeat_age>=0 or g.growth.opened or g.map_open or g.story.modal() or g.has_meta("opening_preview"):return
	var sprite:Sprite2D
	if used>=sprites.size():
		sprite=Sprite2D.new();sprite.centered=false
		var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/combat_signal.gdshader")
		sprite.material=mat;g.add_child(sprite);sprites.append(sprite)
	else:sprite=sprites[used]
	used+=1
	var region:Rect2=atlas.cells[index]
	sprite.texture=atlas.texture;sprite.region_enabled=true;sprite.region_rect=region
	sprite.position=rect.position-g.camera.round()
	sprite.position+=g._camera_kick()
	sprite.scale=rect.size/region.size
	sprite.material.set_shader_parameter("signal_color",color)
	sprite.material.set_shader_parameter("strength",strength)
	sprite.material.set_shader_parameter("phase",g.clock)
	sprite.material.set_shader_parameter("solid",solid)
	var dimensions:=Vector2(atlas.texture.get_size())
	sprite.material.set_shader_parameter("atlas_region",Vector4(region.position.x/dimensions.x,region.position.y/dimensions.y,region.size.x/dimensions.x,region.size.y/dimensions.y))
	sprite.material.set_shader_parameter("charge",charge)
	sprite.show()
