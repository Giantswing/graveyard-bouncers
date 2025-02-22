shader_type canvas_item;

// --- Master Tint Color ---
uniform vec4 master_tint: source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Dissolve Effect ---
uniform float dissolve_percentage: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform sampler2D burn_texture;
group_uniforms layer_1;
uniform vec4 layer_1: source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float size_1 = 0.05;
group_uniforms layer_2;
uniform vec4 layer_2: source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float size_2 = 0.05;
group_uniforms layer_3;
uniform vec4 layer_3: source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float size_3 = 0.05;

// --- Hit Flash Effect ---
uniform bool hit_active = false;

// --- Outline Effect ---
uniform vec4 outline_color: source_color = vec4(1.0);
uniform float outline_width: hint_range(0, 10) = 1.0;
uniform int outline_pattern: hint_range(0, 2) = 0;
uniform bool outline_inside = false;
uniform bool outline_add_margins = true;
uniform vec2 number_of_images = vec2(1.0);
uniform vec4 outline_tint: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// --- Functions ---
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, vec2 image_top_left, vec2 image_bottom_right, sampler2D texture) {
    for (float i = -ceil(outline_width); i <= ceil(outline_width); i++) {
        float x = abs(i) > outline_width ? outline_width * sign(i) : i;
        float offset;

        if (outline_pattern == 0) {
            offset = outline_width - abs(x);
        } else if (outline_pattern == 1) {
            offset = floor(sqrt(pow(outline_width + 0.5, 2) - x * x));
        } else {
            offset = outline_width;
        }

        for (float j = -ceil(offset); j <= ceil(offset); j++) {
            float y = abs(j) > offset ? offset * sign(j) : j;
            vec2 xy = uv + texture_pixel_size * vec2(x, y);

            if ((xy != clamp(xy, image_top_left, image_bottom_right) || texture(texture, xy).a <= 0.0) == outline_inside) {
                return true;
            }
        }
    }
    return false;
}

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    vec2 image_top_left = floor(uv * number_of_images) / number_of_images;
    vec2 image_bottom_right = image_top_left + vec2(1.0) / number_of_images;

    if (outline_add_margins) {
        vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_width * 2.0) * number_of_images);
        uv = (uv - texture_pixel_size * outline_width - image_top_left) * TEXTURE_PIXEL_SIZE / texture_pixel_size + image_top_left;

        if (uv != clamp(uv, image_top_left, image_bottom_right)) {
            COLOR.a = 0.0;
        } else {
            base_color *= outline_tint;
        }
    }

    if ((base_color.a > 0.0) == outline_inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, image_top_left, image_bottom_right, TEXTURE)) {
        base_color.rgb = outline_inside ? mix(base_color.rgb, outline_color.rgb, outline_color.a) : outline_color.rgb;
        base_color.a += (1.0 - base_color.a) * outline_color.a;
    }

    // --- Dissolve Effect ---
    float noise = texture(burn_texture, UV).r * (1.0 - (size_1 + size_2 + size_3 + 0.01));
    base_color.a -= step(dissolve_percentage, noise);
    base_color.rgb = mix(base_color.rgb, layer_3.rgb, step(dissolve_percentage, noise + size_1 + size_2 + size_3));
    base_color.rgb = mix(base_color.rgb, layer_2.rgb, step(dissolve_percentage, noise + size_1 + size_2));
    base_color.rgb = mix(base_color.rgb, layer_1.rgb, step(dissolve_percentage, noise + size_1));

    // --- Hit Flash Effect ---
    if (hit_active) {
        base_color = vec4(1.0, 1.0, 1.0, base_color.a);
    }

    // --- Apply Master Tint ---
    base_color.rgb *= master_tint.rgb;

    COLOR = base_color;
}

