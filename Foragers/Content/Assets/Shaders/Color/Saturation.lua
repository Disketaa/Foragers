return {
	name = "Saturation",
	order = 10,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = { u_saturation = 1 },
	code = [[
vec4 Saturation_color(vec4 color, vec2 screen_coords) {
	float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(lum), color.rgb, u_saturation);
	return color;
}
]],
}