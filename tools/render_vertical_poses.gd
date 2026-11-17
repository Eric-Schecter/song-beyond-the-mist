extends SceneTree
class Poses extends Node2D:
	var player:=Vector2.ZERO
	var atlas=preload("res://scripts/refined_atlas.gd").new()
	func _ready():atlas.open("res://assets/refined/village/cast.png",4,4)
	func _draw():
		for row in range(2):
			for frame in range(6):
				draw_set_transform(Vector2(70+frame*140,130+row*160),0,Vector2.ONE*5)
				preload("res://scripts/vertical_gait.gd").draw(self,atlas,row*2,(frame+.01)*TAU/6,1,Color.WHITE)
func _initialize():run.call_deferred()
func run():
	var viewport:=SubViewport.new();viewport.size=Vector2i(840,320);viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport);viewport.add_child(Poses.new())
	await process_frame;await process_frame
	RenderingServer.force_draw(false)
	viewport.get_texture().get_image().save_png("res://recordings/handmade-vertical-poses.png")
	quit()
