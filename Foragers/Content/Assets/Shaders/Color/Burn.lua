return {
	name = "Burn",
	type = "color",
	module = true,
	uniforms = {
		u_burn = 0,
		u_time = 0,
		u_seed = 0,
		u_canvasScale = 1,
		u_canvasOrigin = { 0, 0 },
	},
	code = [[
float bayer4(vec2 p) {
	vec2 f = mod(p, 4.0);
	int x = int(f.x);
	int y = int(f.y);
	mat4 m = mat4(
		 0.0,  8.0,  2.0, 10.0,
		12.0,  4.0, 14.0,  6.0,
		 3.0, 11.0,  1.0,  9.0,
		15.0,  7.0, 13.0,  5.0
	);
	return m[x][y] / 16.0;
}

vec4 Burn_color(vec4 color, vec2 screen_coords) {
	if (u_burn <= 0.0 || color.a == 0.0) {
		return color;
	}

	vec2 px = floor((screen_coords - u_canvasOrigin) / u_canvasScale);
	float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));

	float t = floor(u_time * 6.0);
	float d = bayer4(px + vec2(u_seed * 17.0, u_seed * 13.0) + vec2(t * 2.0, t));

	float threshold = u_burn - lum + d * 0.10;

	if (threshold >= 0.0) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}

	return color;
}
]],
}
