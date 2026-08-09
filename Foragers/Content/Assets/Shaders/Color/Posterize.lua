return {
	name = "Posterize",
	order = 15,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = { u_posterize = 0 },
	code = [[
vec4 Posterize_color(vec4 color, vec2 screen_coords) {
	if (u_posterize <= 0.0) {
		return color;
	}
	// Reduce channel granularity as intensity rises: subtle banding near the
	// low-satiety threshold, heavy posterization at death.
	float levels = mix(24.0, 4.0, u_posterize);
	color.rgb = floor(color.rgb * levels + 0.5) / levels;
	return color;
}
]],
}
