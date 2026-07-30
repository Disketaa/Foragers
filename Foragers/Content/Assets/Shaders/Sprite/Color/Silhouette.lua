return {
	name = "Silhouette",
	type = "color",
	module = true,
	uniforms = { u_silhouetteThreshold = 0.1 },
	code = [[
extern Image u_silhouetteTexture;

vec4 Silhouette_color(vec4 color, vec2 screen_coords) {
	vec4 sil = Texel(u_silhouetteTexture, screen_coords / love_ScreenSize.xy);
	if (sil.a > u_silhouetteThreshold) {
		return vec4(1.0, 1.0, 1.0, color.a);
	}
	return color;
}
]],
}
