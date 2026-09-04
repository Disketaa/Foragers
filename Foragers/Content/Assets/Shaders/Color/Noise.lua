return {
	name = "Noise",
	order = 16,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = {
		u_noise = 0,
		u_noiseTime = 0,
		u_noiseStrength = 0.1,
		u_noiseRate = 120,
		u_canvasScale = 1,
		u_canvasOrigin = { 0, 0 },
	},
	code = [[
float Noise_hash(vec3 p) {
	vec3 p3 = fract(p * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec4 Noise_color(vec4 color, vec2 screen_coords) {
	if (u_noise <= 0.0) {
		return color;
	}
	// Sample in canvas pixels so the grain follows the game pixel grid.
	vec2 px = floor((screen_coords - u_canvasOrigin) / u_canvasScale);
	// Quantize time to whole steps (u_noiseRate/sec). Fold step in as the z axis
	// so grain stays in place and just re-rolls each step (not px + step, which
	// translated the whole field diagonally).
	float step = floor(u_noiseTime * u_noiseRate);
	float g = Noise_hash(vec3(px, step)) - 0.5;
	color.rgb += g * u_noiseStrength * u_noise;
	return color;
}
]],
}