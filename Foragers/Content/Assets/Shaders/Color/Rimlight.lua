return {
	name = "Rimlight",
	type = "color",
	module = true,
	uniforms = {
		u_rim_angle = 0,
		u_coneWidth = 0.9,
		u_inner = 0.7,
		u_outer = 1,
		u_color = { 1, 0.85, 0.5 },
		u_rim_strength = 0.9,
		u_threshold = 1,
	},
	code = [[
const float PI = 3.14159265;

vec4 Rimlight_color(vec4 color, vec2 screen_coords) {
	float strength = u_rim_strength;
	if (strength <= 0.0 || color.a == 0.0) {
		return color;
	}
	// Brightness threshold: only apply rim to pixels whose luminance is at or
	// above u_threshold (1.0 = disabled).
	if (u_threshold < 1.0) {
		float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		if (lum < u_threshold) {
			return color;
		}
	}
	// Sprite-local uv, written by ShaderLoader's effect() wrapper.
	vec2 puv = _rimlight_uv - vec2(0.5);
	// Box-distance: cards are axis-aligned rectangles, so a radial ring would
	// bunch up at corners. Box-distance yields a uniform-width edge band.
	float r = max(abs(puv.x), abs(puv.y)) * 2.0;
	if (r < u_inner || r > u_outer) {
		return color;
	}
	// Angular distance from the cone direction (u_rim_angle in radians).
	float ang = atan(puv.y, puv.x);
	float diff = mod(ang - u_rim_angle + PI, 2.0 * PI) - PI;
	float cone = 1.0 - clamp(abs(diff) / u_coneWidth, 0.0, 1.0);
	float mid = (u_inner + u_outer) * 0.5;
	float band = smoothstep(u_inner, mid, r) * (1.0 - smoothstep(mid, u_outer, r));
	float rim = cone * band * strength;
	return vec4(color.rgb + u_color * rim, color.a);
}
]],
}