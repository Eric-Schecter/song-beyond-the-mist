extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://combo_lab.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	for id in preload("res://scripts/cc0_combat_audio.gd").MATERIALS.keys():
		var voices:Array=g.material_voices[id]
		assert(voices.size()==3)
		assert(voices[0]!=voices[1],"separate playback voices")
		assert(voices[0].stream.resource_path.begins_with("res://assets/audio/cc0_combat/"),"uses licensed recording")
		for voice in voices:
			var data:PackedByteArray=voice.stream.data
			var peak:=0
			for i in range(0,data.size(),2):peak=maxi(peak,absi(data.decode_s16(i)))
			assert(peak>500 and peak<30000,"audible with headroom")
		g._play(id);var first=g.sounds[id]
		g._play("combo_tap");g._play(id);var second=g.sounds[id]
		assert(first!=second and first.playing and second.playing,"independent variants preserve previous tail")
		for voice in voices:voice.stop()
	print("PASS enemy and player material voices, licensed samples, audio headroom and overlapping tails")
	g.queue_free();await process_frame;quit()
