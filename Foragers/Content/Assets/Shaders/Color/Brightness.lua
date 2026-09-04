return {
	name = "Brightness",
	type = "color",
	module = true,
	uniforms = { u_brightness = 0.5 },
	code = [[
vec4 Brightness_color(vec4 color, vec2 screen_coords) {
	if (color.a == 0) {
		return color;
	}
	float t = u_brightness;
	vec3 mixed;
	if (t < 0.5) {
		mixed = mix(vec3(0), color.rgb, t * 2);
	} else {
		mixed = mix(color.rgb, vec3(1), (t - 0.5) * 2);
	}
	return vec4(mixed, color.a);
}
]],
}