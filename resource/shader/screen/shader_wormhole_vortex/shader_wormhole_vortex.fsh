///@package io.alkapivo.core
///@description shader_wormhole_vortex

#define PI 3.14159265359
#define TAU 6.28318530718
#define DEG_TO_RAD 0.01745329251
#define SQRT_3 1.732050807568877

const mat3 rgb2yiq = mat3(
  0.299, 0.587, 0.114,
  0.595716, -0.274453, -0.321263,
  0.211456, -0.522591, 0.311135
);

const mat3 yiq2rgb = mat3(
  1.0, 0.9563, 0.6210,
  1.0, -0.2721, -0.6474,
  1.0, -1.1070, 1.7046
);
///*
varying vec2 v_texcoord;
varying vec4 v_color;

uniform float u_angle;
uniform float u_bold;
uniform float u_bpm;
uniform float u_brightness;
uniform float u_depth;
uniform float u_direction;
uniform float u_glare;
uniform float u_hue;
uniform float u_intensity;
uniform float u_invert;
uniform float u_iterations;
uniform float u_rotation;
uniform float u_sat;
uniform float u_seed;
uniform float u_shift;
uniform float u_size;
uniform float u_time;
uniform vec2 u_offset;
uniform vec2 u_resolution;
uniform vec3 u_color_in;
uniform vec3 u_color_out;
//*/

// ------------------------------------------------------------
// Utility functions
// ------------------------------------------------------------

vec2 rotated_uv_resolution(
  vec2 texcoord,
  vec2 resolution,
  vec2 origin,
  float angle_deg
) {
  //vec2 coord = (texcoord * 2.0 - resolution) / resolution.y;
  //vec2 origin_ndc = (origin * resolution * 2.0 - resolution) / resolution.y;
  vec2 coord = (texcoord * 2.0 - 1.0) * (resolution / resolution.y);
  vec2 origin_ndc = (origin * 2.0 - 1.0) * (resolution / resolution.y);

  coord -= origin_ndc;

  float angle = angle_deg * DEG_TO_RAD;
  float c = cos(angle);
  float s = sin(angle);

  return vec2(
    coord.x * c - coord.y * s,
    coord.x * s + coord.y * c
  );
}

vec2 rot_cs(vec2 p, float c, float s) {
  return vec2(
    c * p.x - s * p.y,
    s * p.x + c * p.y
  );
}

vec2 rot(vec2 p, float angle) {
  return rot_cs(p, cos(angle), sin(angle));
}

vec2 pmod(vec2 p, float n) {
  float np = TAU / n;
  float r = atan(p.x, p.y) - 0.5 * np;
  r = mod(r, np) - 0.5 * np;

  return length(p) * vec2(cos(r), sin(r));
}

float get_alpha_from_pixel(vec3 pixel) {
  return dot(pixel, vec3(0.2126, 0.7152, 0.0722));
}

float get_color_distance(vec3 color_from, vec3 color_to) {
  return length(color_from - color_to) / SQRT_3;
}

vec3 apply_saturation(vec3 color, float saturation) {
  float luma = get_alpha_from_pixel(color);
  return mix(vec3(luma), color, saturation);
}

vec3 apply_hue(vec3 color, float hue) {
  vec3 y_color = color * rgb2yiq;

  float original_hue = atan(y_color.b, y_color.g);
  float final_hue = original_hue + hue * TAU;

  float chroma = length(y_color.gb);

  return vec3(
    y_color.r,
    chroma * cos(final_hue),
    chroma * sin(final_hue)
  ) * yiq2rgb;
}


// ------------------------------------------------------------
// Distance functions
// ------------------------------------------------------------

float dist(vec3 p, float direction, float time, float size) {
  p.z += direction * time;

  p.xy = rot(p.xy, p.z);
  p.xy = pmod(p.xy, 6.0);

  float zid = floor(p.z * size);

  p = mod(p, size) - 0.5 * size;

  // Precompute rotation values outside the inner loop.
  float a = 1.0 + zid + 0.1 * time;
  float b = 1.0 + 5.0 * zid + 0.25 * time;

  float ca = cos(a);
  float sa = sin(a);
  float cb = cos(b);
  float sb = sin(b);

  for (int i = 0; i < 4; i++) {
    p = abs(p) - 0.3;

    p.xy = rot_cs(p.xy, ca, sa);
    p.xz = rot_cs(p.xz, cb, sb);
  }

  // Inline cube SDF.
  vec3 q = abs(p);
  vec3 m = max(vec3(0.3) - q, 0.0);

  float boxDist =
    length(max(q - 0.3, 0.0))
    - min(min(m.x, m.y), m.z);

  float sphereDist = length(p) - 0.4;

  return min(boxDist, sphereDist);
}


// ------------------------------------------------------------
// Main shader
// ------------------------------------------------------------

void main() {
//void mainImage(out vec4 fragColor, in vec2 v_texcoord) {
  /*
  vec4 v_color = vec4(1.0);
  float u_angle = 0.0;
  float u_bold = 2.0;
  float u_bpm = 76.0;
  float u_brightness = 1.0;
  float u_depth = 2.0;
  float u_direction = -1.0;
  float u_glare = 0.1;
  float u_hue = 0.0;
  float u_intensity = 3.0;
  float u_invert = 1.0;
  float u_iterations = 30.0;
  float u_rotation = 1.0;
  float u_sat = 1.0;
  float u_seed = 0.0;
  float u_shift = 0.1;
  float u_size = 0.7;
  float u_time = iTime;
  vec2 u_offset = vec2(0.5, 0.5);
  vec2 u_resolution = iResolution.xy;
  vec3 u_color_in = vec3(0.1, 0.7, 0.7);
  vec3 u_color_out = vec3(0.1, 1.0, 0.1);
  */

  float direction = sign(u_direction);
  float invert = sign(u_invert);
  float rotation = sign(u_rotation);

  float bpm = (u_bpm / 60.0) * TAU;
  float time = u_time + u_seed;
  float pulse = (sin(time * bpm) + 1.0) * 0.5;

  vec2 uv = rotated_uv_resolution(
    v_texcoord,
    u_resolution,
    u_offset,
    u_angle
  );

  uv = rot(uv, rotation * time);

  vec3 ro = vec3(0.0, 0.0, u_shift);
  vec3 rd = normalize(vec3(uv, 0.0) - ro);

  float t = u_depth;
  float d = 0.0;
  float ac = 0.0;

  // Preserve original iteration semantics.
  for (int i = 0; i < 64; i++) {
    if (float(i) > u_iterations) {
      break;
    }

    d = abs(dist(
      ro + rd * t,
      direction,
      time,
      u_size
    ) * 0.2);

    t += d;

    if (d < 0.002) {
      ac += exp(-15.0 * d) * u_glare;
    }
  }

  vec3 pn = ro * invert + rd * t * invert;

  pn.z = mod(
    pn.z + direction * time,
    0.5
  ) - 0.25 * pulse;

  float em = clamp(0.01 / pn.z, 0.0, 100.0);

  //vec4 texture = vec4(0.0, 0.0, 0.0, 1.0);
  //vec4 texture = texture(iChannel0, v_texcoord / iResolution.xy);
  vec4 textureColor = texture2D(gm_BaseTexture, v_texcoord);

  vec3 color =
    u_color_in * u_intensity * vec3(ac);

  color = clamp(
    color + u_intensity * em * u_color_out,
    0.0,
    1.0
  );

  vec3 pixel =
    apply_hue(
      apply_saturation(color, u_sat),
      u_hue
    ) * u_brightness;

  float alpha = sign(textureColor.a) * clamp(
    get_color_distance(vec3(0.0), pixel) * u_bold,
    0.0,
    1.0
  );

  pixel = mix(pixel, textureColor.rgb, 1.0 - v_color.a);
  pixel = mix(pixel, textureColor.rgb, 1.0 - alpha);

  //fragColor = vec4(color, 1.0);
  //fragColor = vec4(pixel, texture.a + (alpha * v_color.a));
  gl_FragColor = vec4(pixel, textureColor.a + alpha * v_color.a);
}
