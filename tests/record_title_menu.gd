extends "res://tests/record_full_chapter.gd"
func run()->void:
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening);game=opening.game
	await frames(240)
	# Empty scenery is no longer a start button.
	var click:=InputEventMouseButton.new();click.position=Vector2(20,200);click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	opening._input(click)
	if not verify(opening.phase==0,"background click does not start"):return
	tap(KEY_DOWN);await frames(120)
	if not verify(opening.selection==1,"Language is second option"):return
	tap(KEY_DOWN);await frames(90)
	if not verify(opening.selection==2,"Quit is third option"):return
	click.position=opening.menu_rect(0).get_center();opening._input(click)
	await frames(240)
	if not verify(opening.phase==1,"New Journey opens prologue"):return
	opening.queue_free();await process_frame;quit()
