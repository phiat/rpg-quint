#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform float u_time_of_day;

out vec4 finalColor;

void main() {
    vec4 texColor = texture(texture0, fragTexCoord);

    // Time-of-day color grading using cosine curves
    // t=0.0 noon, t=0.25 dusk, t=0.5 midnight, t=0.75 dawn, t=1.0 noon
    float t = u_time_of_day;
    float angle = t * 6.28318530718; // 2*PI

    // Decompose into day/night/dusk/dawn factors using smooth cosine blending
    float dayFactor    = max(0.0, cos(angle));                      // peaks at noon (0.0)
    float nightFactor  = max(0.0, -cos(angle));                     // peaks at midnight (0.5)
    float duskFactor   = max(0.0, -sin(angle));                     // peaks at dusk (0.25)
    float dawnFactor   = max(0.0, sin(angle));                      // peaks at dawn (0.75)

    // Normalize so they sum to something reasonable
    float total = dayFactor + nightFactor + duskFactor + dawnFactor + 0.001;

    // Color tints for each phase
    vec3 dayTint   = vec3(1.02, 1.0, 0.95);   // warm white, slight yellow
    vec3 duskTint  = vec3(1.1, 0.75, 0.6);    // orange-pink
    vec3 nightTint = vec3(0.4, 0.4, 0.7);     // deep blue-purple
    vec3 dawnTint  = vec3(1.0, 0.85, 0.75);   // pale pink-gold

    // Brightness multipliers
    float dayBright   = 1.0;
    float duskBright  = 0.8;
    float nightBright = 0.45;
    float dawnBright  = 0.85;

    // Blend tint and brightness
    vec3 tint = (dayFactor * dayTint + nightFactor * nightTint + duskFactor * duskTint + dawnFactor * dawnTint) / total;
    float brightness = (dayFactor * dayBright + nightFactor * nightBright + duskFactor * duskBright + dawnFactor * dawnBright) / total;

    vec3 color = texColor.rgb * tint * brightness;

    // Vignette - stronger at night
    vec2 uv = fragTexCoord - 0.5;
    float dist = dot(uv, uv);
    float vignetteStrength = mix(0.15, 0.6, nightFactor / total);
    float vignette = 1.0 - dist * vignetteStrength * 2.5;
    vignette = clamp(vignette, 0.0, 1.0);
    color *= vignette;

    finalColor = vec4(color, texColor.a);
}
