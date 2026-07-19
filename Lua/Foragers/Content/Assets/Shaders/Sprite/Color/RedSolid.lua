return {
	name = "RedSolid",
	type = "color",
	module = true,
	uniforms = {},
	code = [[
vec4 RedSolid_color(vec4 color) {
	return vec4(1.0, color.g * 0.3, color.b * 0.3, color.a);
}
]],
}
