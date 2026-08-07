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
		float checker = mod(floor(screen_coords.x) + floor(screen_coords.y), 2.0);
		if (checker > 0.5) {
			return vec4(sil.rgb, sil.a * color.a);
		}
	}
	return color;
}
]],
}
