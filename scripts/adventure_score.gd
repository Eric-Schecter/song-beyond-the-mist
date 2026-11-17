extends Node
var game: Node2D
var music := AudioStreamPlayer.new()
var battle := AudioStreamPlayer.new()
var outgoing := AudioStreamPlayer.new()
var context := "adventure"
var transition := 1.0
const TRACKS={"title":"mist_title_theme.wav","history":"mist_history_story.wav","adventure":"morning_adventure.wav"}
var battle_mix := 0.0
var boss_active := false

func loop_stream(path: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = load(path).duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=stream.data.size()/(4 if stream.stereo else 2)
	return stream

func _ready() -> void:
	context=str(game.get_meta("music_context","adventure")) if game!=null else "adventure"
	music.stream=loop_stream("res://assets/music/"+TRACKS[context])
	battle.stream=loop_stream("res://assets/music/guardian_battle.wav")
	add_child(music);add_child(battle);add_child(outgoing)
	music.volume_db=-17;battle.volume_db=-80
	music.play()

func set_context(next:String)->void:
	if next==context:return
	outgoing.stream=music.stream
	outgoing.volume_db=music.volume_db
	outgoing.play(music.get_playback_position())
	context=next
	music.stream=loop_stream("res://assets/music/"+TRACKS[context])
	music.volume_db=-80
	music.play()
	transition=0.0

func _process(delta: float) -> void:
	if game==null:return
	if game.has_meta("music_context"):
		set_context(str(game.get_meta("music_context")))
	transition=move_toward(transition,1.0,delta/1.5)
	outgoing.volume_db=linear_to_db(maxf(.0001,db_to_linear(-17.0)*(1-transition)))
	if transition==1 and outgoing.playing:outgoing.stop()
	boss_active=game.story_enabled and game.story.stage==game.story.Stage.GUARD and (game.slime_health>0 or game.boss_death>0)
	if boss_active and not battle.playing: battle.play()
	battle_mix=move_toward(battle_mix,1.0 if boss_active else 0.0,delta/(1.1 if boss_active else 2.0))
	var base_db: float = -19.0 if context=="history" else -17.0
	music.volume_db=linear_to_db(maxf(.0001,db_to_linear(base_db)*(1-battle_mix)*transition))
	battle.volume_db=linear_to_db(maxf(.0001,db_to_linear(-16.0)*battle_mix))
	if not boss_active and battle_mix==0 and battle.playing:battle.stop()
