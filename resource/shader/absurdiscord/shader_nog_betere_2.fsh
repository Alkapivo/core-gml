///@shader shader_nog_betere_2
///@author https://www.shadertoy.com/view/NtlSzX
///@description Fragment shade

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float iTime;
uniform vec2 iResolution;


///@param {vec2} uv
///@return {vec3}
vec3 color(in vec2 uv) {
  float c = (1.2 + sin(iTime * 0.1)*0.2) - log(0.7 + distance(uv, vec2(sin(iTime*0.1), 0.5 + cos(iTime*0.25) * 0.2)));
  vec3 col = vec3(c * 0.7, c * 0.9 + cos(iTime*0.2) * 0.1, c * 0.9 + cos(iTime*0.5) * 0.1);

  for (float i = 0.0; i < 10.0; i++) {
      if (uv.y > (sin(iTime * 0.4) + sin(uv.x + iTime + i/6.0 + log(iTime) / log(3.0) * 3.0 + (iTime + sin(iTime * 0.3)) * 0.5)) * 0.1) col *= 0.92;
  }

  return col;
}


void main() {
  vec2 uv = (v_vTexcoord - 0.5 * iResolution.xy) / iResolution.y;

  vec3 _color = color(uv);
  vec4 pixel = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
  pixel.a = _color.r * _color.g * _color.b * pixel.a;
  pixel.r = _color.r + pixel.r * 0.3;
  pixel.g = _color.g + pixel.g * 0.2;
  pixel.b = _color.b + pixel.b * 0.5;
  gl_FragColor = pixel;
}
