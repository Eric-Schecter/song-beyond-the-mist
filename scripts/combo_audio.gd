extends RefCounted
# Seeded noise + swept resonances: each gesture has its own timing and spectrum.
static func build(id:String)->AudioStreamWAV:
	var durations={"light1":.10,"light2":.12,"light3":.17,"thrust":.18,"spin":.43,"heavy":.24,"charged":.38,"chase":.09,"charge":.65,"impact":.18,"tap":.08,"critical":.22}
	var duration:float=durations[id]
	var stream:=AudioStreamWAV.new();stream.mix_rate=22050;stream.format=AudioStreamWAV.FORMAT_16_BITS
	var data:=PackedByteArray();var count:=int(duration*22050);data.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=931+id.hash()
	var low:=0.0;var phase:=0.0
	for i in range(count):
		var t:float=float(i)/22050;var u:float=t/duration
		var noise:float=rng.randf_range(-1,1);low=lerpf(low,noise,.16)
		var high:float=noise-low
		var wave:float=high*.45;var env:float=pow(sin(PI*u),1.5)
		match id:
			"light1","light2","light3":
				phase+=TAU*lerpf(1700 if id=="light2" else 1100,340,u)/22050
				wave=high*.38+sin(phase)*.035+low*.55
			"thrust":
				phase+=TAU*lerpf(2400,650,u)/22050;wave=high*.42+sin(phase)*.045;env=pow(sin(PI*u),2)
			"spin":
				phase+=TAU*lerpf(700,300,u)/22050;wave=low*1.3+high*.15+sin(phase)*.08
				env*=.3+.7*pow(sin(u*PI*3),2)
			"heavy","charged":
				phase+=TAU*lerpf(430,75,u)/22050;wave=low*1.8+high*.18+sin(phase)*.065;env=pow(sin(PI*u),.8)
			"chase":wave=high*.55;env=pow(1-u,2)*minf(u*18,1)
			"charge":
				phase+=TAU*lerpf(150,520,u)/22050;wave=sin(phase)*.12+low*.2;env=u*(1-smoothstep(.9,1,u))
			"tap":
				phase+=TAU*lerpf(250,95,u)/22050;wave=sin(phase)*.35+high*.5*exp(-60*t);env=exp(-45*t)*minf(t/.001,1)
			"critical":
				wave=sin(TAU*2400*t)*.12*exp(-35*t)+sin(TAU*3617*t)*.07*exp(-48*t)+high*.24*exp(-65*t);env=exp(-12*t)*minf(t/.001,1)
			"impact":
				phase+=TAU*lerpf(160,48,u)/22050;wave=sin(phase)*.55+low*.9+high*.35*exp(-45*t);env=exp(-20*t)*minf(t/.002,1)
		data.encode_s16(i*2,int(clampf(wave*env,-1,1)*14000))
	stream.data=data;return stream
