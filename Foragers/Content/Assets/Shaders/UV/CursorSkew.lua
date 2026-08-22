return {
	name = "CursorSkew",
	type = "uv",
	module = true,
	uniforms = { u_cursor = { 0, 0 }, u_amount = 0.05 },
	code = [[
vec2 CursorSkew_uv(vec2 uv, vec2 screen_coords) {
	vec2 c = uv - 0.5;
	// Homogeneous divide (not affine shear) so all four corners foreshorten
	// toward the cursor: depth < 1 near cursor (forward/larger), > 1 far (recedes).
	float depth = 1.0 - (u_cursor.x * u_amount) * c.x - (u_cursor.y * u_amount) * c.y;
	uv = c / depth + 0.5;
	return uv;
}
]],
}
