return {
	name = "Rimlight",
	type = "color",
	module = true,
	uniforms = {
		u_rim_angle = 0,
		u_coneWidth = 0.9,
		u_inner = 0.7,
		u_outer = 1.0,
		u_color = { 1, 0.85, 0.5 },
		u_rim_strength = 0.9,
		u_threshold = 1.0,
	},
	code = [[
vec4 Rimlight_color(vec4 color, vec2 screen_coords) {
	float strength = u_rim_strength;
	if (strength <= 0 || color.a == 0) {
		return color;
	}
	// Brightness threshold: only apply rim to pixels whose luminance is at or
	// above u_threshold (1.0 = disabled, rim applies to all lit pixels).
	if (u_threshold < 1.0) {
		float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		if (lum < u_threshold) {
			return color;
		}
	}
	// Sprite-local uv, written by ShaderLoader's effect() wrapper.
	vec2 puv = _rimlight_uv - vec2(0.5);
	// Normalized distance to the nearest edge (0 = center, 1 = edge).
	// Percentage-based so u_inner/u_outer map to card-edge fractions regardless
	// of sprite aspect ratio.
	float r = max(abs(puv.x), abs(puv.y)) * 2.0;
	if (r < u_inner || r > u_outer) {
		return color;
	}
	// Angular distance from the cone direction (u_rim_angle in radians).
	float ang = atan(puv.y, puv.x);
	float diff = mod(ang - u_rim_angle + 3.14159265, 6.28318530) - 3.14159265;
	float cone = 1.0 - clamp(abs(diff) / u_coneWidth, 0.0, 1.0);
	// Soft falloff at inner/outer edges for a feathered ring.
	float band = smoothstep(u_inner, (u_inner + u_outer) * 0.5, r)
		* (1.0 - smoothstep((u_inner + u_outer) * 0.5, u_outer, r));
	float rim = cone * band * strength;
	return vec4(color.rgb + u_color * rim, color.a);
}
]],
}