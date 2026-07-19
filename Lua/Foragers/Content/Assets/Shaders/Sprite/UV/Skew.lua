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
		u_curve = 2.0,
	},
	code = [[
vec2 Skew_uv(vec2 uv, vec2 screen_coords) {
	float wave = sin(u_time * u_speed + u_seed);

	// Bend, not shear: base fixed, tip follows an arc. Height factor grows
	// non-linearly toward the top so rows blend into a curve, no staircase.
	float t = clamp(1.0 - uv.y, 0.0, 1.0);
	float h = pow(t, u_curve) * u_gradient;
	float base = (1.0 - u_gradient) * 0.5; // when gradient<1, whole sprite still sways a bit

	float sway = base + h;
	float offsetX = wave * u_amount * sway;
	float offsetY = sin(u_time * u_speed * 0.7 + u_seed) * u_amount * 0.15 * (base + h);

	return uv + vec2(offsetX, offsetY);
}
]],
}
