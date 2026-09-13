return {
	name = "Gradient",
	type = "color",
	module = true,
	uniforms = {
		u_colorA = { 1, 1, 1 },
		u_colorB = { 1, 1, 1 },
		u_angle = 0,
		u_canvasSize = { 0, 0 },
		u_rangeMin = 0,
		u_rangeMax = 1,
	},
	code = [[
vec4 Gradient_color(vec4 color, vec2 screen_coords) {
	if (color.a == 0) {
		return color;
	}
	vec2 size = max(u_canvasSize, vec2(1.0));
	vec2 uv = screen_coords / size;
	vec2 dir = vec2(cos(radians(u_angle)), sin(radians(u_angle)));
	float raw = dot(uv, dir);

	float lo = min(u_rangeMin, u_rangeMax);
	float hi = max(u_rangeMin, u_rangeMax);
	float t = (hi > lo) ? (raw - lo) / (hi - lo) : raw;
	t = clamp(t, 0.0, 1.0);

	vec3 g = mix(u_colorA, u_colorB, t);
	return vec4(g, color.a);
}
]],
}