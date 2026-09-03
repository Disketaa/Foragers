return {
	name = "Palette",
	type = "color",
	module = true,
	uniforms = {
		u_tier_1 = { 1, 1, 1 },
		u_tier_2 = { 1, 1, 1 },
		u_tier_3 = { 1, 1, 1 },
		u_tier_4 = { 1, 1, 1 },
		u_tier_5 = { 1, 1, 1 },
	},
	code = [[
vec4 Palette_color(vec4 color, vec2 screen_coords) {
	vec4 texcolor = color;
	float lum = texcolor.r;
	float diff = abs(texcolor.r - texcolor.g) + abs(texcolor.g - texcolor.b);
	if (diff > 0.02 || lum < 0.5) {
		return texcolor;
	}
	vec3 result = mix(u_tier_5, u_tier_4, step(0.65, lum));
	result = mix(result, u_tier_3, step(0.75, lum));
	result = mix(result, u_tier_2, step(0.85, lum));
	result = mix(result, u_tier_1, step(0.95, lum));
	return vec4(result, texcolor.a);
}
]],
}
