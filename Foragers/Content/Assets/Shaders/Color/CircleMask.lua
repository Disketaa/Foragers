return {
	name = "CircleMask",
	order = 20,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = {
		u_circleRadius = 0,
		u_softness = 32,
		u_canvasScale = 1,
		u_canvasOrigin = { 0, 0 },
	},
	code = [[
float bayer2(vec2 p) {
	vec2 f = mod(floor(p), 2.0);
	mat2 m = mat2(
		vec2(0.0, 3.0),
		vec2(2.0, 1.0)
	);
	return (0.5 + m[int(f.x)][int(f.y)]) / 4.0;
}

vec4 CircleMask_color(vec4 color, vec2 screen_coords) {
	if (u_circleRadius <= 0) {
		return color;
	}
	// Convert window pixels back to canvas pixels (blit scale + output zoom),
	// then snap to whole canvas-pixel centers so the circle edge, dither cells
	// and gradient steps all follow the game pixel grid (nearest-neighbor look)
	// at any window size and zoom — no sub-pixel smoothing.
	vec2 px = floor((screen_coords - u_canvasOrigin) / u_canvasScale) + 0.5;
	vec2 center = floor((love_ScreenSize.xy * 0.5 - u_canvasOrigin) / u_canvasScale) + 0.5;
	// Radial gradient: 1 (clear) inside the circle, 0 (black) outside. The
	// dithered band crosses the boundary from outside into the circle.
	float t = clamp((u_circleRadius - distance(px, center)) / u_softness + 0.5, 0.0, 1.0);
	float black = step(bayer2(px), 1.0 - t);
	return mix(color, vec4(0.0, 0.0, 0.0, 1.0), black);
}
]],
}