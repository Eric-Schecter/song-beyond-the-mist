extends "res://tests/record_wild_art.gd"

# Keep setup gameplay intact; advance already-reviewed opening dialogue faster.
# The delivered clip begins after this setup, at the village departure.
func read_dialogue() -> void:
	await frames(2)
	while not game.story.pages.is_empty():
		var line: String = str(game.story.pages[game.story.page][1])
		var setup_dialogue: bool = game.story.stage < game.story.Stage.KEYS
		await frames(18 if setup_dialogue else maxi(125,int(line.length()*4.8)))
		tap(KEY_E)
		await frames(2)
