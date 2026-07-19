return {
	name = "Skew",
	type = "uv",
	module = true,
	uniforms = {
		u_time = 0,
		u_speed = 1.0,
		u_amount = 0.1,
		u_seed = 0.0,
		u_gradient = 1.0,
	},
	code = [[
vec2 Skew_uv(vec2 uv, vec2 screen_coords) {
	float wave = sin(u_time * u_speed + u_seed);

	// Skew: each row shifts by its height. Bottom (uv.y=1) stays, top (uv.y=0) moves most.
	// u_gradient scales how much the top leads the bottom (0 = flat translate, 1 = full skew).
	float h = (1.0 - uv.y) * u_gradient;
	float base = (1.0 - u_gradient) * 0.5; // when gradient<1, whole sprite still sways a bit

	float offsetX = wave * u_amount * (base + h);
	float offsetY = sin(u_time * u_speed * 0.7 + u_seed) * u_amount * 0.15 * (base + h);

	return uv + vec2(offsetX, offsetY);
}
]],
}
