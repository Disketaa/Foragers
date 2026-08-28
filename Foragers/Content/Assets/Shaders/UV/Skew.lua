return {
	name = "Skew",
	type = "uv",
	module = true,
	uniforms = { u_skewAngle = 0, u_amount = 0.1, u_strength = 0 },
	code = [[
vec2 Skew_uv(vec2 uv, vec2 screen_coords) {
	vec2 c = uv - 0.5;
	vec2 dir = vec2(cos(u_skewAngle), sin(u_skewAngle));
	float depth = 1.0 - u_strength * (dir.x * u_amount) * c.x - u_strength * (dir.y * u_amount) * c.y;
	uv = c / depth + 0.5;
	return uv;
}
]],
}