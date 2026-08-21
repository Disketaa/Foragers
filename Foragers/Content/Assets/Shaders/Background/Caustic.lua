return {
	name = "Caustic",
	priority = "background",
	applies_to = "screen",
	uniforms = {
		caustic_color = { 0.25, 0.65, 0.9 },
		speed = 0.2,
		horizontal_scale = 0.2,
		vertical_scale = 0.1,
		threshold = 0.9,
		sharpness = 0.9,
		glow_intensity = 0.9,
		glow_threshold = 0.1,
		opacity_variation = 0.33,
	},
	code = [[
extern vec3 caustic_color;
extern float speed;
extern float horizontal_scale;
extern float vertical_scale;
extern float threshold;
extern float sharpness;
extern float glow_intensity;
extern float glow_threshold;
extern float opacity_variation;
extern float time;
extern float camera_x;
extern float camera_y;

float simpleHash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = simpleHash(i);
    float b = simpleHash(i + vec2(1, 0));
    float c = simpleHash(i + vec2(0, 1));
    float d = simpleHash(i + vec2(1, 1));
    vec2 u = f * f * (3 - 2 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1 - u.x) + (d - b) * u.x * u.y;
}

vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
    if (threshold >= 1 && glow_intensity <= 0) {
        return vec4(0);
    }

    float ct = time * speed;

    mat3 cm = mat3(
        -2, -1, 2,
         3, -2, 1,
         1,  2, 2
    );

    // bgCanvas has no translate, so subtract camera offset from screen_coords to match world space
    // (no parallax, 1x with world)
    vec2 world_coords = screen_coords - vec2(camera_x, camera_y);

    vec4 cp = vec4(world_coords.x / horizontal_scale / 100,
                   world_coords.y / vertical_scale / 100,
                   0, ct);

    vec3 tc1 = vec3(cp.x, cp.y, cp.w) * (cm * 0.5);
    cp = vec4(tc1.x, tc1.y, cp.z, tc1.z);
    float r1 = length(0.5 - fract(cp.xyw));

    vec3 tc2 = vec3(cp.x, cp.y, cp.w) * (cm * 0.4);
    cp = vec4(tc2.x, tc2.y, cp.z, tc2.z);
    float r2 = length(0.5 - fract(cp.xyw));

    vec3 tc3 = vec3(cp.x, cp.y, cp.w) * (cm * 0.3);
    cp = vec4(tc3.x, tc3.y, cp.z, tc3.z);
    float r3 = length(0.5 - fract(cp.xyw));

    float ci = 1 - pow(min(min(r1, r2), r3), 7) * 25;
    float base = 1 - smoothstep(threshold, threshold + 0.3, ci);
    float glow = (1 - smoothstep(glow_threshold, glow_threshold + 0.6, ci)) * glow_intensity;

    if (sharpness > 0) {
        float cutoff = 0.5 + sharpness * 0.5;
        base = mix(base, step(cutoff, base), sharpness);
        glow = mix(glow, step(cutoff, glow), sharpness);
    }

    float alpha = base;

    if (opacity_variation > 0) {
        float scale = max(horizontal_scale, vertical_scale);
        float noise = smoothNoise(world_coords * (0.005 / scale) + ct * 0.05);
        alpha *= mix(1, 1 - noise, opacity_variation);
    }

    vec3 fc = caustic_color + vec3(1) * glow;
    return vec4(fc, alpha);
}
]],
}
