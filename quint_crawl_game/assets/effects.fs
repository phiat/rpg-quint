#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;

// Zone color tint (set per-frame based on current zone)
uniform vec3 u_zone_tint;      // rgb multiplier, default (1,1,1)

// Chromatic aberration + barrel distortion on hit
uniform float u_aberration;    // 0.0 = none, 1.0 = max (driven by shake_timer)

// Low-HP danger pulse
uniform float u_danger;        // 0.0 = safe, 1.0 = critical (HP ratio inverted)
uniform float u_time;          // global time for pulse animation

// Level-up bloom
uniform float u_bloom;         // 0.0 = none, 1.0 = max flash

// Poison screen tint
uniform float u_poison;        // 0.0 = none, 1.0 = full poison effect

// Per-biome animated tile effect (applied via UV wobble, pre-sample)
// 0 = none, 1 = swamp ripples, 2 = castle heat shimmer
uniform int u_tile_effect;

// CRT scanlines (retro toggle)
uniform float u_scanlines;     // 0.0 = off, 1.0 = full

out vec4 finalColor;

// Simple hash for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = fragTexCoord;
    vec2 center = vec2(0.5, 0.5);

    // --- Animated tile UV wobble (swamp / castle biomes) ---
    if (u_tile_effect == 1) {
        // Swamp: slow horizontal ripples
        uv.x += sin(uv.y * 18.0 + u_time * 1.5) * 0.004;
        uv.y += cos(uv.x * 12.0 + u_time * 1.0) * 0.003;
    } else if (u_tile_effect == 2) {
        // Castle: heat shimmer, stronger near bottom
        float heat = (1.0 - uv.y) * 0.006;
        uv.x += sin(uv.y * 40.0 + u_time * 4.0) * heat;
    }

    // --- Barrel distortion on hit (effect 4) ---
    if (u_aberration > 0.01) {
        vec2 d = uv - center;
        float r2 = dot(d, d);
        float distortion = u_aberration * 0.15; // subtle
        uv = center + d * (1.0 + distortion * r2);
        uv = clamp(uv, 0.0, 1.0);
    }

    // --- Chromatic aberration on hit (effect 3) ---
    vec3 color;
    if (u_aberration > 0.01) {
        float offset = u_aberration * 0.008; // max ~8px at 1000px wide
        color.r = texture(texture0, uv + vec2(offset, 0.0)).r;
        color.g = texture(texture0, uv).g;
        color.b = texture(texture0, uv - vec2(offset, 0.0)).b;
    } else {
        color = texture(texture0, uv).rgb;
    }

    // --- Zone color tint (effect 2) ---
    color *= u_zone_tint;

    // --- Poison tint (effect 10) ---
    if (u_poison > 0.01) {
        // Boost green, reduce red/blue, slight vertical UV wobble baked in
        float wobble = sin(uv.y * 40.0 + u_time * 3.0) * u_poison * 0.003;
        vec3 poison_sample = texture(texture0, uv + vec2(0.0, wobble)).rgb;
        vec3 poison_tint = vec3(0.7, 1.2, 0.7);
        color = mix(color, poison_sample * poison_tint, u_poison * 0.4);
    }

    // --- Low-HP danger pulse (effect 5) ---
    if (u_danger > 0.01) {
        // Heartbeat rhythm: two quick pulses then pause
        float beat = u_time * 4.0;
        float pulse = max(sin(beat), 0.0) * max(sin(beat * 1.3 + 0.5), 0.0);
        pulse = pulse * pulse; // sharpen

        // Red vignette from edges
        vec2 d = fragTexCoord - center;
        float edge_dist = length(d) * 1.5;
        float danger_intensity = u_danger * pulse * edge_dist;
        color = mix(color, vec3(0.8, 0.05, 0.05), danger_intensity * 0.5);
    }

    // --- Level-up bloom (effect 6) ---
    if (u_bloom > 0.01) {
        // Additive white bloom that decays
        color += vec3(u_bloom * 0.8);
        // Slight saturation boost
        float lum = dot(color, vec3(0.299, 0.587, 0.114));
        color = mix(vec3(lum), color, 1.0 + u_bloom * 0.3);
    }

    // --- CRT scanlines (retro toggle) ---
    if (u_scanlines > 0.01) {
        // Horizontal dark bands every other pixel row
        float line = sin(fragTexCoord.y * 540.0) * 0.5 + 0.5;
        float sl = mix(1.0, 0.78 + 0.22 * line, u_scanlines);
        color *= sl;
        // Subtle RGB subpixel tint
        float col = mod(floor(fragTexCoord.x * 960.0), 3.0);
        vec3 subpixel = vec3(1.0);
        if (col < 1.0) subpixel = vec3(1.04, 0.98, 0.98);
        else if (col < 2.0) subpixel = vec3(0.98, 1.04, 0.98);
        else subpixel = vec3(0.98, 0.98, 1.04);
        color *= mix(vec3(1.0), subpixel, u_scanlines * 0.5);
    }

    // Clamp final output
    color = clamp(color, 0.0, 1.0);

    float alpha = texture(texture0, fragTexCoord).a;
    finalColor = vec4(color, alpha);
}
