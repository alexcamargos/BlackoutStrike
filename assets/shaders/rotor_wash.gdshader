shader_type spatial;
render_mode blend_mix, cull_back, unshaded;

uniform vec4 wash_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float ring_frequency = 18.0;
uniform float expansion_speed = 4.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);

    float wave = sin(dist * ring_frequency - TIME * expansion_speed);
    float falloff = 1.0 - smoothstep(0.1, 0.95, dist);

    float alpha_mask = clamp(wave * falloff * intensity, 0.0, 1.0);

    ALBEDO = wash_color.rgb;
    ALPHA = alpha_mask * wash_color.a;
}
