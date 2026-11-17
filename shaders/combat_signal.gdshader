shader_type canvas_item;
render_mode unshaded;
uniform vec4 signal_color : source_color = vec4(1.0,0.72,0.3,1.0);
uniform float strength = 0.25;
uniform bool solid = false;
uniform float phase = 0.0;
uniform vec4 atlas_region = vec4(0.0,0.0,1.0,1.0);
uniform float charge = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p=(UV-atlas_region.xy)/atlas_region.zw;
	vec2 step_uv=TEXTURE_PIXEL_SIZE*2.0;
	float inside=min(min(texture(TEXTURE,UV+vec2(step_uv.x,0)).a,texture(TEXTURE,UV-vec2(step_uv.x,0)).a),min(texture(TEXTURE,UV+vec2(0,step_uv.y)).a,texture(TEXTURE,UV-vec2(0,step_uv.y)).a));
	float rim=clamp(tex.a-inside,0.0,1.0);
	float pulse=.5+.5*sin(phase*(7.0+charge*10.0));
	float sweep=pow(max(0.0,1.0-abs(p.y-fract(phase*.8))*7.0),2.0);
	vec2 cell=floor(p*vec2(18.0,28.0));
	float grain=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
	float sparks=step(.92,grain)*pow(max(0.0,sin(phase*9.0+grain*30.0)),6.0);
	float energy=.22+pulse*.35+sweep*.65+sparks*.7+rim*1.6+charge*.35;
	vec3 tint=mix(signal_color.rgb,vec3(1.0,.96,.80),clamp(sweep*.45+rim*.5+charge*.15,0.0,.8));
	COLOR=vec4(solid ? signal_color.rgb:tint,tex.a*strength*(solid ? 1.0:energy));
}
