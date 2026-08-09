return {
	name = "Darken",
	order = 30,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = { u_darken = 0 },
	code = [[
vec4 Darken_color(vec4 color, vec2 screen_coords) {
	return vec4(color.rgb * (1.0 - u_darken), color.a);
}
]],
}
