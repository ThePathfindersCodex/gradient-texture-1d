shader_type canvas_item;

uniform sampler2D gradient_texture : filter_linear, repeat_disable, source_color;

// Gradient mode: 0 = linear, 1 = diagonal, 2 = radial, 3 = conical, 4 = grayscale map
uniform int gradient_mode = 0;

// Steps: 0 = smooth, >0 = posterized
uniform int steps = 0;

// Hue shift: 0 = original, 1 = full 360 rotation
uniform float hue_shift = 0.0;

// Center for radial/conical gradients
uniform vec2 gradient_center = vec2(0.5, 0.5);

// ---------------- RGB to HSV helpers ----------------
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(
        vec4(c.bg, K.wz),
        vec4(c.gb, K.xy),
        step(c.b, c.g)
    );
    vec4 q = mix(
        vec4(p.xyw, c.r),
        vec4(c.r, p.yzx),
        step(p.x, c.r)
    );
    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return vec3(
        abs(q.z + (q.w - q.y) / (6.0 * d + e)),
        d / (q.x + e),
        q.x
    );
}
vec3 hsv2rgb(vec3 c)
{
    vec3 K = vec3(1.0, 2.0/3.0, 1.0/3.0);
    vec3 p = abs(fract(c.xxx + K) * 6.0 - 3.0);
    return c.z * mix(
        vec3(1.0),
        clamp(p - 1.0, 0.0, 1.0),
        c.y
    );
}

// ---------------- Compute gradient coordinate ----------------
float compute_t(vec2 uv, sampler2D src_texture) {
    if (gradient_mode == 0) {
        // Linear left to right
        return uv.x;
    } else if (gradient_mode == 1) {
        // Diagonal top-left to bottom-right
        return (uv.x + uv.y) * 0.5;
    } else if (gradient_mode == 2) {
        // Radial from center
        float d = distance(uv, gradient_center);
        float max_d = length(vec2(0.5, 0.5));
        return d / max_d;
    } else if (gradient_mode == 3) {
        // Conical (clockwise starting up)
        vec2 dir = uv - gradient_center;
        float angle = atan(dir.y, dir.x) + PI * 0.5; // rotate so 12 oclock is start
        return fract(angle / (2.0 * PI) + 1.0);
    } else if (gradient_mode == 4) {
        // Grayscale texture to gradient coordinate
        vec4 tex = texture(src_texture, uv).rgba;
        if (tex.a <= 0.001) 
			return 0.0;
		float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
        return gray;
    }
    return uv.x;
}

// ---------------- Apply posterized steps ----------------
float apply_steps(float t) {
    if (steps <= 0) return t;
    float s = float(steps);
    return floor(t * s) / s;
}

// ---------------- Fragment ----------------
void fragment() {
    // 1. Compute gradient coordinate
    float t = compute_t(UV, TEXTURE);
    t = clamp(t, 0.0, 1.0);
    t = apply_steps(t);

    // 2. Sample gradient
    vec4 color = texture(gradient_texture, vec2(t, 0.5));

    // 3. Apply optional hue shift
	float apply = step(0.0001, abs(hue_shift)); // apply only if hue shift is not zero
	vec3 hsv = rgb2hsv(color.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	vec3 shifted = hsv2rgb(hsv);
	color.rgb = mix(color.rgb, shifted, apply);

	// 4. Final output
	COLOR = color;
	vec4 src = texture(TEXTURE, UV);
	COLOR.a = color.a * src.a; // preserve sprite transparency
}
