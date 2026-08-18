return {
	name = "DayCycle",
	order = 25,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = { u_dayTime = 12 },
	code = [[
// Day/night tint keyframes: hour -> rgba. Edit the gradient here, not in Lua.
// alpha = blend amount over the scene; rgb = tint color.
const int KF_COUNT = 7;
const float kfHour[KF_COUNT] = float[](0.0, 6.0, 7.0, 8.0, 18.0, 19.0, 21.0);
const vec4 kfColor[KF_COUNT] = vec4[](
	vec4(0.05, 0.05, 0.15, 0.6),  // midnight
	vec4(0.05, 0.05, 0.15, 0.6),  // pre-dawn
	vec4(0.9, 0.5, 0.3, 0.2),     // dawn
	vec4(0.0, 0.0, 0.0, 0.0),     // sunrise done (full day)
	vec4(0.0, 0.0, 0.0, 0.0),     // sunset start (full day)
	vec4(0.9, 0.4, 0.2, 0.3),     // dusk
	vec4(0.05, 0.05, 0.15, 0.6)   // night
);

vec4 DayCycle_color(vec4 color, vec2 screen_coords) {
	vec4 tint = kfColor[KF_COUNT - 1];
	if (u_dayTime < kfHour[1]) {
		tint = mix(kfColor[0], kfColor[1], (u_dayTime - kfHour[0]) / (kfHour[1] - kfHour[0]));
	} else if (u_dayTime < kfHour[2]) {
		tint = mix(kfColor[1], kfColor[2], (u_dayTime - kfHour[1]) / (kfHour[2] - kfHour[1]));
	} else if (u_dayTime < kfHour[3]) {
		tint = mix(kfColor[2], kfColor[3], (u_dayTime - kfHour[2]) / (kfHour[3] - kfHour[2]));
	} else if (u_dayTime < kfHour[4]) {
		tint = mix(kfColor[3], kfColor[4], (u_dayTime - kfHour[3]) / (kfHour[4] - kfHour[3]));
	} else if (u_dayTime < kfHour[5]) {
		tint = mix(kfColor[4], kfColor[5], (u_dayTime - kfHour[4]) / (kfHour[5] - kfHour[4]));
	} else if (u_dayTime < kfHour[6]) {
		tint = mix(kfColor[5], kfColor[6], (u_dayTime - kfHour[5]) / (kfHour[6] - kfHour[5]));
	}
	// Blend the tint over the scene by its alpha (over-style), preserving the
	// scene's own alpha so transparent pixels stay transparent.
	vec3 blended = mix(color.rgb, tint.rgb, tint.a);
	return vec4(blended, color.a);
}
]],
}
