///@package io.alkapivo.core
///@description shader_wavy_mesh_optimized

#define PI    3.141592
#define TAU     6.283185
#define DEG_TO_RAD 0.017453
#define SQRT_3  1.732050

const mat3 rgb2yiq = mat3(
  0.299,    0.587,    0.114,
  0.595716,  -0.274453,  -0.321263,
  0.211456,  -0.522591,   0.311135
);

const mat3 yiq2rgb = mat3(
  1.0,  0.9563,  0.6210,
  1.0, -0.2721, -0.6474,
  1.0, -1.1070,  1.7046
);

varying vec2 v_texcoord;
varying vec4 v_color;

uniform float u_angle;
uniform float u_border;
uniform float u_brightness;
uniform float u_fbm_scale;
uniform float u_fbm_size;
uniform float u_hue;
uniform float u_jitter;
uniform float u_mesh_size;
uniform float u_sat;
uniform float u_seed;
uniform float u_shift;
uniform float u_thickness;
uniform float u_time;

uniform vec2 u_offset;
uniform vec2 u_resolution;

uniform vec3 u_color_between;
uniform vec3 u_color_bkg;
uniform vec3 u_color_mesh;


// ------------------------------------------------------------
// Hash
// ------------------------------------------------------------

vec2 hash2(vec2 p)
{
  float n = dot(p, vec2(127.1, 311.7));

  // Same basic hash as original, but vectorized.
  return fract(
    sin(vec2(n, n + 78.233)) *
    vec2(43758.5453123, 23421.631)
  );
}


// ------------------------------------------------------------
// Noise
// ------------------------------------------------------------

float noise(vec2 p)
{
  vec2 i = floor(p);
  vec2 f = fract(p);

  // Hermite interpolation.
  vec2 u = f * f * (3.0 - 2.0 * f);

  float n = dot(i, vec2(127.1, 311.7));

  // Four corner hashes.
  vec4 h = fract(
    sin(vec4(
      n,
      n + 127.1,
      n + 311.7,
      n + 438.8
    )) * 43758.5453
  );

  float a = h.x;
  float b = h.y;
  float c = h.z;
  float d = h.w;

  return mix(a, b, u.x)
     + (c - a) * u.y * (1.0 - u.x)
     + (d - b) * u.x * u.y;
}


float fbm(vec2 p)
{
  float f = 0.5 * noise(p);

  p *= 2.02;
  f += 0.25 * noise(p);

  p *= 2.03;
  f += 0.125 * noise(p);

  p *= 2.01;
  f += 0.0625 * noise(p);

  return f;
}


float pulse(vec2 p, float time)
{
  float life = fbm(p + time);
  float pulsev = sin(life * PI);

  // Original:
  // fade = 1 - abs(pulsev - 1)
  // Since pulsev is normally [0,1], this is simply pulsev.
  return clamp(pulsev, 0.0, 1.0);
}


// ------------------------------------------------------------
// Geometry
// ------------------------------------------------------------

float line_shape_fast(
  vec2 uv,
  vec2 a,
  vec2 b,
  float thickness
)
{
  vec2 pa = uv - a;
  vec2 ba = b - a;

  float denom = max(dot(ba, ba), 1e-6);
  float h = clamp(dot(pa, ba) / denom, 0.0, 1.0);

  vec2 diff = pa - ba * h;
  float d = length(diff);

  return smoothstep(thickness, thickness * 0.5, d);
}


float triangle_fill_fast(
  vec2 uv,
  vec2 a,
  vec2 b,
  vec2 c,
  float border
)
{
  vec2 ba = b - a;
  vec2 ca = c - a;

  float area = ba.x * ca.y - ca.x * ba.y;

  // Avoid division by zero.
  float inv_area = 1.0 / max(abs(area), 1e-6);

  float wa =
    (uv.x * (b.y - c.y)
    + b.x * (c.y - uv.y)
    + c.x * (uv.y - b.y)) * inv_area;

  float wb =
    (uv.x * (c.y - a.y)
    + c.x * (a.y - uv.y)
    + a.x * (uv.y - c.y)) * inv_area;

  float wc =
    (uv.x * (a.y - b.y)
    + a.x * (b.y - uv.y)
    + b.x * (uv.y - a.y)) * inv_area;

  float edge = min(min(wa, wb), wc);

  return smoothstep(border, border + 0.05, edge);
}


// ------------------------------------------------------------
// Vertex calculation
// ------------------------------------------------------------

vec2 vertex_position(
  vec2 cell,
  float time,
  float jitter_scale
)
{
  vec2 h = hash2(cell);

  vec2 animated =
    vec2(
      sin(h.x * TAU + time * 1.2),
      cos(h.y * TAU + time * 1.3)
    );

  return (
    cell
    + 0.5
    + u_shift
    + (h - 0.5 + animated * 0.5) * jitter_scale
  ) / u_mesh_size;
}


float vertex_fade(vec2 cell, float time)
{
  float f = pulse(cell, time);

  // Original:
  // f *= f * f
  return f * f * f;
}


vec3 rainbow(float t)
{
  return 0.5 + 0.5 *
    cos(TAU * (vec3(0.00, 0.33, 0.66) + t));
}


// ------------------------------------------------------------
// Edge + triangle processing
// ------------------------------------------------------------

vec3 add_edge(
  vec3 color,
  vec2 uv,
  vec2 a,
  vec2 b,
  float fade,
  float thickness
)
{
  float t = thickness * fade;

  float line =
    line_shape_fast(
      uv,
      a,
      b,
      t
    ) * fade;

  color +=
    mix(
      u_color_mesh,
      u_color_between,
      line * 0.5
    ) * line;

  return color;
}


vec3 add_triangle(
  vec3 color,
  vec2 uv,
  vec2 a,
  vec2 b,
  vec2 c,
  float fade,
  float osc,
  float random_value
)
{
  float fill =
    triangle_fill_fast(
      uv,
      a,
      b,
      c,
      u_border
    ) * osc;

  vec3 tri_col =
    rainbow(random_value) + 1.0;

  color +=
    u_color_bkg *
    fill *
    tri_col *
    fade *
    osc;

  return color;
}


// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void main()
{
  // --------------------------------------------------------
  // Coordinate transform
  // --------------------------------------------------------

  float angle_rad = u_angle * DEG_TO_RAD;

  float cos_a = cos(angle_rad);
  float sin_a = sin(angle_rad);

  vec2 origin_ndc =
    (u_offset * u_resolution);

  origin_ndc =
    (origin_ndc * 2.0 - u_resolution)
    / u_resolution.y;

  vec2 coord =
    (v_texcoord * u_resolution * 2.0
    - u_resolution)
    / u_resolution.y;

  coord -= origin_ndc;

  vec2 uv_rot =
    vec2(
      coord.x * cos_a - coord.y * sin_a,
      coord.x * sin_a + coord.y * cos_a
    );

  vec2 uv = uv_rot * u_mesh_size;

  vec2 grid = floor(uv);

  vec2 pixel_uv = uv_rot;

  // --------------------------------------------------------
  // Time / oscillation
  // --------------------------------------------------------

  float time =
    (u_time + u_seed) * 0.5;

  uv +=
    vec2(
      cos(time),
      sin(time)
    ) * angle_rad;

  float n =
    noise(uv * u_fbm_scale);

  float fbm_size =
    clamp(abs(u_fbm_size), 0.0, 1.0);

  float osc =
    fbm_size +
    (1.0 - fbm_size) *
    sin(time + n * TAU);

  // --------------------------------------------------------
  // Precompute constants
  // --------------------------------------------------------

  float jitter_scale =
    u_jitter / u_mesh_size;

  float line_thickness =
    0.005 * u_thickness;

  // --------------------------------------------------------
  // Local 4x4 vertex grid
  //
  // The 3x3 cells require only 4x4 unique vertices.
  // --------------------------------------------------------

  vec2 p00 = vertex_position(grid + vec2(-1.0, -1.0), time, jitter_scale);
  vec2 p10 = vertex_position(grid + vec2( 0.0, -1.0), time, jitter_scale);
  vec2 p20 = vertex_position(grid + vec2( 1.0, -1.0), time, jitter_scale);
  vec2 p30 = vertex_position(grid + vec2( 2.0, -1.0), time, jitter_scale);

  vec2 p01 = vertex_position(grid + vec2(-1.0,  0.0), time, jitter_scale);
  vec2 p11 = vertex_position(grid + vec2( 0.0,  0.0), time, jitter_scale);
  vec2 p21 = vertex_position(grid + vec2( 1.0,  0.0), time, jitter_scale);
  vec2 p31 = vertex_position(grid + vec2( 2.0,  0.0), time, jitter_scale);

  vec2 p02 = vertex_position(grid + vec2(-1.0,  1.0), time, jitter_scale);
  vec2 p12 = vertex_position(grid + vec2( 0.0,  1.0), time, jitter_scale);
  vec2 p22 = vertex_position(grid + vec2( 1.0,  1.0), time, jitter_scale);
  vec2 p32 = vertex_position(grid + vec2( 2.0,  1.0), time, jitter_scale);

  vec2 p03 = vertex_position(grid + vec2(-1.0,  2.0), time, jitter_scale);
  vec2 p13 = vertex_position(grid + vec2( 0.0,  2.0), time, jitter_scale);
  vec2 p23 = vertex_position(grid + vec2( 1.0,  2.0), time, jitter_scale);
  vec2 p33 = vertex_position(grid + vec2( 2.0,  2.0), time, jitter_scale);

  // --------------------------------------------------------
  // Vertex fades
  //
  // 16 unique vertices instead of repeatedly calculating
  // the same pulse() values.
  // --------------------------------------------------------

  float f00 = vertex_fade(grid + vec2(-1.0, -1.0), time);
  float f10 = vertex_fade(grid + vec2( 0.0, -1.0), time);
  float f20 = vertex_fade(grid + vec2( 1.0, -1.0), time);
  float f30 = vertex_fade(grid + vec2( 2.0, -1.0), time);

  float f01 = vertex_fade(grid + vec2(-1.0,  0.0), time);
  float f11 = vertex_fade(grid + vec2( 0.0,  0.0), time);
  float f21 = vertex_fade(grid + vec2( 1.0,  0.0), time);
  float f31 = vertex_fade(grid + vec2( 2.0,  0.0), time);

  float f02 = vertex_fade(grid + vec2(-1.0,  1.0), time);
  float f12 = vertex_fade(grid + vec2( 0.0,  1.0), time);
  float f22 = vertex_fade(grid + vec2( 1.0,  1.0), time);
  float f32 = vertex_fade(grid + vec2( 2.0,  1.0), time);

  float f03 = vertex_fade(grid + vec2(-1.0,  2.0), time);
  float f13 = vertex_fade(grid + vec2( 0.0,  2.0), time);
  float f23 = vertex_fade(grid + vec2( 1.0,  2.0), time);
  float f33 = vertex_fade(grid + vec2( 2.0,  2.0), time);

  vec3 color = vec3(0.0);

  // --------------------------------------------------------
  // 3x3 cells
  // --------------------------------------------------------

  // Cell (-1,-1)
  color = add_edge(color, pixel_uv, p00, p01, f00 * f01, line_thickness);
  color = add_edge(color, pixel_uv, p00, p10, f00 * f10, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p00, p01, p10,
    f00 * f01 * f10,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(-2.0, -3.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (0,-1)
  color = add_edge(color, pixel_uv, p10, p11, f10 * f11, line_thickness);
  color = add_edge(color, pixel_uv, p10, p20, f10 * f20, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p10, p11, p20,
    f10 * f11 * f20,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(0.0, -3.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (1,-1)
  color = add_edge(color, pixel_uv, p20, p21, f20 * f21, line_thickness);
  color = add_edge(color, pixel_uv, p20, p30, f20 * f30, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p20, p21, p30,
    f20 * f21 * f30,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(2.0, -3.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (-1,0)
  color = add_edge(color, pixel_uv, p01, p02, f01 * f02, line_thickness);
  color = add_edge(color, pixel_uv, p01, p11, f01 * f11, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p01, p02, p11,
    f01 * f02 * f11,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(-2.0, 0.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (0,0)
  color = add_edge(color, pixel_uv, p11, p12, f11 * f12, line_thickness);
  color = add_edge(color, pixel_uv, p11, p21, f11 * f21, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p11, p12, p21,
    f11 * f12 * f21,
    osc,
    time + fract(dot(
      grid * 3.0,
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (1,0)
  color = add_edge(color, pixel_uv, p21, p22, f21 * f22, line_thickness);
  color = add_edge(color, pixel_uv, p21, p31, f21 * f31, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p21, p22, p31,
    f21 * f22 * f31,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(2.0, 0.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (-1,1)
  color = add_edge(color, pixel_uv, p02, p03, f02 * f03, line_thickness);
  color = add_edge(color, pixel_uv, p02, p12, f02 * f12, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p02, p03, p12,
    f02 * f03 * f12,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(-2.0, 2.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (0,1)
  color = add_edge(color, pixel_uv, p12, p13, f12 * f13, line_thickness);
  color = add_edge(color, pixel_uv, p12, p22, f12 * f22, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p12, p13, p22,
    f12 * f13 * f22,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(0.0, 2.0),
      vec2(12.9898, 78.233)
    ))
  );

  // Cell (1,1)
  color = add_edge(color, pixel_uv, p22, p23, f22 * f23, line_thickness);
  color = add_edge(color, pixel_uv, p22, p32, f22 * f32, line_thickness * 1.5);

  color = add_triangle(
    color, pixel_uv,
    p22, p23, p32,
    f22 * f23 * f32,
    osc,
    time + fract(dot(
      grid * 3.0 + vec2(2.0, 2.0),
      vec2(12.9898, 78.233)
    ))
  );

  // --------------------------------------------------------
  // Color processing
  // --------------------------------------------------------

  vec3 pixel = color;

  float luma =
    dot(
      pixel,
      vec3(0.2126, 0.7152, 0.0722)
    );

  pixel =
    mix(
      vec3(luma),
      pixel,
      u_sat
    );

  if (abs(u_hue) > 1e-5)
  {
    vec3 yiq = pixel * rgb2yiq;

    float hue =
      atan(
        yiq.b,
        yiq.g
      ) + u_hue * TAU;

    float chroma =
      sqrt(
        yiq.b * yiq.b +
        yiq.g * yiq.g
      );

    pixel =
      vec3(
        yiq.r,
        chroma * cos(hue),
        chroma * sin(hue)
      ) * yiq2rgb;
  }

  pixel *= u_brightness;

  // --------------------------------------------------------
  // Texture compositing
  // --------------------------------------------------------

  vec4 tex =
    texture2D(
      gm_BaseTexture,
      v_texcoord
    );

  float alpha =
    tex.a == 0.0
    ? 0.0
    : distance(tex.rgb, pixel) / SQRT_3;

  pixel =
    mix(
      pixel,
      tex.rgb,
      1.0 - alpha
    );

  gl_FragColor =
    vec4(
      pixel,
      tex.a + alpha * v_color.a
    );
}
