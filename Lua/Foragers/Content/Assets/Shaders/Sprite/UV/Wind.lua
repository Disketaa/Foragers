return {
	name = "Wind",
	type = "uv",
	module = true,
	uniforms = {
		u_time = 0,
		u_windSpeed = 2.0,
		u_amount = 0.5,
		u_cellCount = 4.0,
		u_idle = 0.1,
	},
	code = [[
float Wind_hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 Wind_uv(vec2 uv, vec2 screen_coords) {
	vec2 dir = vec2(0.7071, 0.7071);

	float t = u_time * u_windSpeed;
	float wave = sin(dot(uv, dir) * 10.0 - t);
	float strength = u_idle + (1.0 - u_idle) * max(wave, 0.0);

	vec2 cell = floor(uv * u_cellCount);
	float stepT = floor(t);
	vec2 off = vec2(Wind_hash21(cell + stepT), Wind_hash21(cell + stepT + 19.7)) - 0.5;
	return uv + off * u_amount * strength / u_cellCount;
}
]],
}
