return {
	name = "Brightness",
	applies_to = "sprite",
	priority = "foreground",
	uniforms = { u_brightness = 0.5 },
	code = [[
extern float u_brightness;

vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
	vec4 texColor = Texel(texture, tex_coords);
	if (texColor.a == 0.0) {
		return texColor;
	}

	float t = u_brightness;
	vec3 mixed;
	if (t < 0.5) {
		mixed = mix(vec3(0.0), texColor.rgb, t * 2.0);
	} else {
		mixed = mix(texColor.rgb, vec3(1.0), (t - 0.5) * 2.0);
	}
	return vec4(mixed, texColor.a * color.a);
}
]],
}
