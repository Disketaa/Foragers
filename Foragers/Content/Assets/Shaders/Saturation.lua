return {
	name = "Saturation",
	priority = "postprocess",
	uniforms = {
		u_saturation = 1,
	},
	code = [[
extern float u_saturation;

vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
	vec4 pixel = Texel(texture, tex_coords);
	float lum = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	pixel.rgb = mix(vec3(lum), pixel.rgb, u_saturation);
	return pixel * color;
}
]],
}
