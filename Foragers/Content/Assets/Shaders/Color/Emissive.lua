return {
	name = "Emissive",
	order = 26,
	postprocess = true,
	type = "color",
	module = true,
	code = [[
vec4 Emissive_color(vec4 color, vec2 screen_coords) {
	return color;
}
]],
}