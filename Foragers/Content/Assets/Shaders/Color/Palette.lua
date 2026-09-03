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
	float diff = abs(texcolor.r - texcolor.g) + abs(texcolor.g - texcolor.b);
	if (diff > 0.02) {
		return texcolor;
	}
	float lum = texcolor.r;
	vec3 result;
	if (lum > 0.95) {
		result = u_tier_1;
	} else if (lum > 0.85) {
		result = u_tier_2;
	} else if (lum > 0.75) {
		result = u_tier_3;
	} else if (lum > 0.65) {
		result = u_tier_4;
	} else if (lum > 0.55) {
		result = u_tier_5;
	} else {
		result = vec3(0.0);
	}
	return vec4(result, texcolor.a);
}
]],
}
