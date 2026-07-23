return {
	name = "Tint",
	type = "color",
	module = true,
	uniforms = {
		u_tint_color = { 1, 0, 1 },
		u_tint_mix = 0,
		u_additive = 0,
	},
	code = [[
vec4 Tint_color(vec4 color) {
	float t = u_tint_mix;
	if (t == 0 || color.a == 0) {
		return color;
	}
	vec3 tinted = mix(color.rgb, u_tint_color, t);
	vec3 added = color.rgb + u_tint_color * t;
	vec3 result = mix(tinted, added, u_additive);
	return vec4(result, color.a);
}
]],
}
