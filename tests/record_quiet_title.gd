extends "res://tests/record_full_chapter.gd"
func run() -> void:
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening);game=opening.game
	await frames(360)
	tap(KEY_ENTER);await frames(240)
	print("TITLE REVIEW phase=",opening.phase," music=",opening.music.playing)
	if not verify(opening.phase==1,"quiet title enters illustrated prologue"):return
	opening.queue_free();await process_frame;quit()
