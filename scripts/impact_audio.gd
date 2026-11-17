extends RefCounted
# Original synthesis: short transient, resonant body, then material debris.
const IDS=["bone_hit","break","plant_hit","plant_die","stone_hit","stone_die","bat_hit","bat_die","armor"]
static func build(kind:String,variant:int)->AudioStreamWAV:
	var duration:float={"bone_hit":.19,"break":.32,"plant_hit":.22,"plant_die":.36,"stone_hit":.28,"stone_die":.65,"bat_hit":.13,"bat_die":.23,"armor":.24}[kind]
	var stream:=AudioStreamWAV.new();stream.mix_rate=32000;stream.format=AudioStreamWAV.FORMAT_16_BITS
	var count:=int(duration*stream.mix_rate);var data:=PackedByteArray();data.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=kind.hash()+variant*7919
	var low:=0.0;var mid:=0.0
	var pitch:=1.0+(variant-1)*.035
	for i in range(count):
		var t:float=float(i)/stream.mix_rate
		var n:=rng.randf_range(-1,1);low=lerpf(low,n,.045);mid=lerpf(mid,n,.32)
		var grit:=mid-low;var high:=n-mid
		var wave:=0.0
		if kind in ["bone_hit","break"]:
			var clicks:=exp(-90*t)
			for delay in [.025,.057,.095,.145]:
				if t>delay:clicks+=.32*exp(-100*(t-delay))
			wave=high*.45*clicks+sin(TAU*760*pitch*t)*.24*exp(-34*t)+sin(TAU*1270*pitch*t)*.12*exp(-48*t)+low*.8*exp(-25*t)
			if kind=="break":wave+=grit*.9*exp(-9*t)*pow(sin(t*110),4)
		elif kind in ["plant_hit","plant_die"]:
			var tear:=exp(-17*t)*(.35+.65*pow(sin(t*133+variant),2))
			wave=grit*1.8*tear+high*.22*exp(-55*t)+sin(TAU*(150*t-170*t*t))* .18*exp(-30*t)
			if kind=="plant_die":wave+=low*1.3*exp(-9*t)*pow(sin(t*85),2)
		elif kind in ["stone_hit","stone_die"]:
			wave=high*.38*exp(-70*t)+sin(TAU*115*pitch*t)*.26*exp(-24*t)+sin(TAU*420*pitch*t)*.15*exp(-32*t)
			for delay in [.034,.071,.12,.18]:
				if t>delay:wave+=grit*.7*exp(-50*(t-delay))
			if kind=="stone_die":wave+=low*2*exp(-5*t)+grit*.55*exp(-6*t)*pow(sin(t*61),4)
		elif kind in ["bat_hit","bat_die"]:
			wave=grit*.85*exp(-38*t)+high*.28*exp(-80*t)+sin(TAU*(980*t-1200*t*t))* .09*exp(-35*t)
			if kind=="bat_die":wave+=grit*.6*exp(-14*t)*pow(sin(t*95),2)
		else:
			wave=high*.3*exp(-100*t)+(sin(TAU*1650*pitch*t)*.2+sin(TAU*2713*pitch*t)*.12)*exp(-22*t)
		var edge:float=minf(t/.0008,1)*(1-smoothstep(duration-.025,duration,t))
		data.encode_s16(i*2,int(clampf(wave*edge,-.9,.9)*22000))
	stream.data=data;return stream
