return {
	name = "Wind",
	type = "uv",
	module = true,
	uniforms = {
		u_time = 0,
		u_windSpeed = 10.5,
		u_amount = 0.5,
		u_cellCount = 2.0,
		u_idle = 0.0,
		u_windDir = { 0.7071, 0.7071 },
		u_waveLength = 3.0,
		u_frequency = 1.5,
	},
	code = [[
float Wind_hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 Wind_uv(vec2 uv, vec2 screen_coords) {
	vec2 windDir = normalize(u_windDir);
	vec2 perpDir = vec2(-windDir.y, windDir.x);

	float t = u_time * u_windSpeed;
	vec2 cell = floor(uv * u_cellCount);
	vec2 cellCenter = (cell + 0.5) / u_cellCount;

	// Per-cell static character, generated ONCE via hash (never from time).
	float cellPhase = Wind_hash21(cell) * 6.2831853;
	float amplitude = u_amount * (0.4 + 0.6 * Wind_hash21(cell + 7.3));
	float rotation = (Wind_hash21(cell + 19.7) - 0.5) * 0.8;
	float response = 0.6 + 0.4 * Wind_hash21(cell + 41.1);

	// Wave front travels along windDir; each cell is offset by its own phase.
	float wave = t * u_frequency + dot(cellCenter, windDir) * u_waveLength + cellPhase;

	// Main sway along wind direction, plus a little cross-axis flutter.
	float along = sin(wave);
	float across = sin(wave * 0.5 + rotation) * response;

	float strength = u_idle + (1.0 - u_idle) * (0.5 + 0.5 * along);
	vec2 offset = (windDir * along + perpDir * across * 0.35) * amplitude * strength;

	return uv + offset / u_cellCount;
}
]],
}
