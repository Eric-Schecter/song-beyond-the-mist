extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.GUARD;g.story.pages.clear()
	g.charge_direction=Vector2.RIGHT
	g.player=g.slime+Vector2(30,0)
	g.patterns.skill_cooldown=0;g.patterns.cycle=1;g.patterns.select(g)
	g.guard_state=g.Guard.WINDUP;g.guard_time=.5
	g.patterns.update(g,0)
	assert(g.health==3,"windup never damages")
	g.guard_time=0;g.patterns.update(g,0);g.patterns.update(g,0)
	assert(g.health==2,"fan strikes front")
	g.hurt_time=0;g.patterns.update(g,0)
	assert(g.health==2,"one hit per attack")
	g.patterns.skill_cooldown=0;g.patterns.cycle=1;g.patterns.select(g)
	g.player=g.slime+Vector2(-20,0);g.guard_state=g.Guard.CHARGE
	g.patterns.update(g,0)
	assert(g.health==2,"behind guardian is safe from fan")
	g.patterns.skill_cooldown=0;g.patterns.cycle=2;g.patterns.select(g)
	g.player+=Vector2(0,80);g.guard_state=g.Guard.CHARGE
	g.patterns.update(g,0)
	assert(g.health==2,"falling rocks lock old positions")
	g.patterns.skill_cooldown=2;g.patterns.select(g)
	assert(g.patterns.kind==3,"skills on cooldown use a basic attack")
	g.player=g.slime+Vector2(20,0);g.health=3;g.hurt_time=0
	g.guard_state=g.Guard.WINDUP;g.guard_time=.2;g.patterns.update(g,0)
	assert(g.health==3,"basic attack has a safe windup")
	g.guard_time=0;g.patterns.update(g,0);g.guard_time=.12;g.patterns.update(g,0)
	assert(g.health==2,"basic attack hits in front")
	g.guard_time=0;g.patterns.update(g,0)
	assert(g.guard_state==g.Guard.RECOVERY and g.guard_time<.5,"basic attack ends in short recovery, not stagger")
	g.player=g.slime+Vector2(-15,0);g.swing_direction=Vector2.RIGHT;g.weapon=g.Weapon.SWORD
	g.slime_health=12;g.guard_time=.25
	g.combat_stats.rng.seed=17;g._resolve_attack()
	assert(g.slime_health<12 and is_equal_approx(g.guard_time,.25),"ordinary hits do not extend recovery")
	g.guard_state=g.Guard.WATCH;g.slime_health=12;g.combat_stats.rng.seed=17;g._resolve_attack()
	assert(g.slime_health<12 and g.guard_state==g.Guard.WATCH,"boss can be damaged outside recovery")
	g.weapon=g.Weapon.SWORD;g.move_name="charged";g.guard_state=g.Guard.WINDUP;g.combat_stats.rng.seed=17;g._resolve_attack()
	assert(g.guard_state==g.Guard.STAGGER and g.guard_time<1,"charged sword earns brief stagger")
	g.slime_health=9;g.guard_state=g.Guard.WATCH;g.guard_time=0
	g.patterns.update(g,0)
	assert(g.patterns.enraged and g.patterns.skill_cooldown==0,"half health unlocks phase two without stunning")
	g.patterns.select(g)
	assert(g.patterns.kind==2,"phase two starts with locked falling rocks")
	g.patterns.select(g)
	assert(g.patterns.kind==3 and g.patterns.followups==1,"phase two basic attack has a follow-up")
	g.guard_state=g.Guard.CHARGE;g.guard_time=0;g.patterns.fired=true
	g.patterns.update(g,0)
	assert(g.guard_state==g.Guard.WINDUP and g.guard_time>=.5,"second swing has a fresh readable windup")
	assert(g.patterns.followups==0,"combo cannot loop forever")
	g.guard_state=g.Guard.CHARGE;g.guard_time=0;g.patterns.fired=true;g.patterns.update(g,0)
	assert(g.guard_state==g.Guard.RECOVERY,"combo ends with a real punish window")
	print("PASS phase transition, skill selection, finite combo and readable follow-up")
	print("PASS basic windup, short recovery, unrestricted damage and earned stagger")
	print("PASS windup safety, fan direction, single impact and locked rock targets")
	quit()
