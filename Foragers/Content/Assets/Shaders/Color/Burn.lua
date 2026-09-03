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
// 4x4 Bayer matrix — fixed pattern, every cell exactly 4x4 pixels.
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

	// Bayer dither perturbs the threshold. Time re-rolls the dither offset
	// so the pattern flickers like fire. u_seed shifts the grid.
	float t = floor(u_time * 6.0);
	float d = bayer4(px + vec2(u_seed * 17.0, u_seed * 13.0) + vec2(t * 2.0, t));

	float noiseScale = 0.10;
	float v1 = u_burn - lum + d * noiseScale;
	float v2 = u_burn - lum - 0.06 + d * noiseScale;
	float v3 = u_burn - lum - 0.12 + d * noiseScale;

	if (v1 >= 0.0) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (v2 >= 0.0) {
		return vec4(1.0, 0.95, 0.7, color.a);
	}
	if (v3 >= 0.0) {
		return vec4(0.0, 0.0, 0.0, color.a);
	}

	float edge = step(-0.04, v1) - step(0.0, v1);
	color.rgb += vec3(1.0, 0.6, 0.2) * edge * 0.5;

	return color;
}
]],
}