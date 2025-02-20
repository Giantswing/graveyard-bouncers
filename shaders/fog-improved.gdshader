shader_type canvas_item;

uniform vec4 color : source_color;
uniform float alpha_multiplier : hint_range(0.0, 5.0) = 1.0;
uniform int OCTAVES = 4;
uniform bool enable_pixelation = true;
uniform int pixelation_amount = 150;
uniform sampler2D fog_mask;
uniform vec2 fog_direction = vec2(1.0, 1.0);
uniform bool scroll_noise_tex = false;
uniform vec2 noise_scroll_direction = vec2(1.0, 0.0);

float rand(vec2 coord) {
    return fract(sin(dot(coord, vec2(56, 78)) * 1000.0) * 1000.0);
}

float noise(vec2 coord) {
    vec2 i = floor(coord);
    vec2 f = fract(coord);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 cubic = f * f * (3.0 - 2.0 * f);

    return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
    float value = 0.0;
    float scale = 0.5;

    for(int i = 0; i < OCTAVES; i++){
        value += noise(coord) * scale;
        coord *= 2.0;
        scale *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 grid_uv = UV;
    if (enable_pixelation) {
        grid_uv = round(UV * float(pixelation_amount)) / float(pixelation_amount);
    }

    // Base coordinate calculation
    vec2 coord = grid_uv * 20.0;

    // Use mod() to keep TIME within a stable range
    float stable_time = mod(TIME, 1000.0);

    // Scroll the noise texture if enabled
    if (scroll_noise_tex) {
        coord += noise_scroll_direction * stable_time;
    }

    // Apply smooth looping motion using sin() and cos() for each axis
    vec2 looped_time = vec2(sin(TIME * 0.1), cos(TIME * 0.1)) * 10.0;

    // Add looped movement to the coordinates
    vec2 motion = vec2(fbm(coord + fog_direction * looped_time));

    // Apply dynamic noise movement
    float final = fbm(coord + motion);

    // Get the fog density from the texture mask
    float mask_value = texture(fog_mask, UV).r;

    // Modulate the fog density by the mask value and final alpha
    COLOR = vec4(color.rgb, final * color.a * alpha_multiplier * mask_value);
}
