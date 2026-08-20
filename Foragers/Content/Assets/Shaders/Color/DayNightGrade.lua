return {
	name = "DayNightGrade",
	order = 25,
	postprocess = true,
	type = "color",
	module = true,
	uniforms = { u_dayTime = 12 },
	code = [[
// Day/night grade keyframes: hour -> rgb grade multiplier. Edit here, not in Lua.
// Two sets: kfColorHighlight (warm grade for lit areas) and kfColorShadow (cool
// grade for shadowed areas). Split-toning gives golden hour its warm-highlight /
// cool-shadow read. Values are MULTIPLIERS (1 = no change): >1 warms/boosts,
// <1 cools/darkens. Applied as a luminance-weighted multiply so highlights stay
// rich (no white blowout) and blacks stay black.
const int KF_COUNT = 7;
// Warm/golden peaks at the HORIZON (6.0 / 18.0), not an hour after: golden hour is
// when the sun is lowest, so color and shadow must peak together. Dusk fade begins
// at 16.5 to match the 1.5h shadow stretch window (shadow.stretchWindow=0.125).
const float kfHour[KF_COUNT] = float[](0.0, 5.0, 6.0, 8.0, 16.5, 18.0, 19.5);
	const vec4 kfColorHighlight[KF_COUNT] = vec4[](
		vec4(0.20, 0.28, 0.55, 1.0),  // midnight (rich deep blue)
		vec4(0.20, 0.28, 0.55, 1.0),  // pre-dawn (rich deep blue)
		vec4(1.50, 0.80, 0.55, 1.0),  // dawn (red-orange) — peaks at horizon 6.0
		vec4(1.0, 1.0, 1.0, 1.0),     // full day (neutral)
		vec4(1.0, 1.0, 1.0, 1.0),     // full day — dusk fade begins 16.5 (matches shadow window)
		vec4(1.40, 0.40, 0.50, 1.0),  // dusk (crimson) — peaks at horizon 18.0
		vec4(0.20, 0.28, 0.55, 1.0)   // night (rich deep blue)
	);
	const vec4 kfColorShadow[KF_COUNT] = vec4[](
		vec4(0.12, 0.18, 0.45, 1.0),  // midnight (rich deep blue shadow, close to highlight)
		vec4(0.12, 0.18, 0.45, 1.0),  // pre-dawn (rich deep blue shadow)
		vec4(1.00, 0.60, 0.55, 1.0),  // dawn (red-orange shadow) — peaks at horizon 6.0
		vec4(1.0, 1.0, 1.0, 1.0),     // full day
		vec4(1.0, 1.0, 1.0, 1.0),     // full day — dusk fade begins 16.5
		vec4(1.00, 0.25, 0.35, 1.0),  // dusk (crimson shadow) — peaks at horizon 18.0
		vec4(0.12, 0.18, 0.45, 1.0)  // night (rich deep blue shadow)
	);

// Lerp both keyframe sets to the current hour.
void DayNightGrade_keys(out vec4 hi, out vec4 sh, float h) {
	hi = kfColorHighlight[KF_COUNT - 1];
	sh = kfColorShadow[KF_COUNT - 1];
	if (h < kfHour[1]) {
		float t = (h - kfHour[0]) / (kfHour[1] - kfHour[0]);
		hi = mix(kfColorHighlight[0], kfColorHighlight[1], t);
		sh = mix(kfColorShadow[0], kfColorShadow[1], t);
	} else if (h < kfHour[2]) {
		float t = (h - kfHour[1]) / (kfHour[2] - kfHour[1]);
		hi = mix(kfColorHighlight[1], kfColorHighlight[2], t);
		sh = mix(kfColorShadow[1], kfColorShadow[2], t);
	} else if (h < kfHour[3]) {
		float t = (h - kfHour[2]) / (kfHour[3] - kfHour[2]);
		hi = mix(kfColorHighlight[2], kfColorHighlight[3], t);
		sh = mix(kfColorShadow[2], kfColorShadow[3], t);
	} else if (h < kfHour[4]) {
		float t = (h - kfHour[3]) / (kfHour[4] - kfHour[3]);
		hi = mix(kfColorHighlight[3], kfColorHighlight[4], t);
		sh = mix(kfColorShadow[3], kfColorShadow[4], t);
	} else if (h < kfHour[5]) {
		float t = (h - kfHour[4]) / (kfHour[5] - kfHour[4]);
		hi = mix(kfColorHighlight[4], kfColorHighlight[5], t);
		sh = mix(kfColorShadow[4], kfColorShadow[5], t);
	} else if (h < kfHour[6]) {
		float t = (h - kfHour[5]) / (kfHour[6] - kfHour[5]);
		hi = mix(kfColorHighlight[5], kfColorHighlight[6], t);
		sh = mix(kfColorShadow[5], kfColorShadow[6], t);
	}
}

vec4 DayNightGrade_color(vec4 color, vec2 screen_coords) {
	vec4 hi, sh;
	DayNightGrade_keys(hi, sh, u_dayTime);
	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	// Split-tone grade: warm on lit pixels, cool on shadowed pixels.
	vec3 grade = mix(sh.rgb, hi.rgb, luma);
	vec3 blended = color.rgb * grade;

	return vec4(blended, color.a);
}
]],
}
