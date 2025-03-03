///@description Based on shader created by Peace in 2024-07-22
///             https://www.shadertoy.com/view/lffyWf

varying vec2 vTexcoord;
varying vec4 vColor;

uniform vec2 iResolution;
uniform float iTime;
uniform float iSize;
uniform float iDistance;

float hash12(vec2 p) {
	vec3 p3 = fract(p.xyx * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float res = mix(
		mix(hash12(i), hash12(i + vec2(1, 0)), f.x),
		mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1)), f.x), 
    f.y
  );

	return res * res;	
}

void main() {
  vec2 uv = (vTexcoord * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);

  float l = sqrt(length(uv));
  float a = l * 9.0 - iTime;
  
  uv = cos(-uv.x + a) * uv + sin(a) * vec2(-uv.y, uv.x);
  
  float n = sqrt(noise(uv * iSize));
  float b = noise(35.185 - uv * 8.0);
  float c = 1.0 / (b + 1.0);
  float s = smoothstep(0.3, 0.6 * c, n * (iDistance - l*l));
  float d = sin(6.0 * n * b) * 0.5 + 0.5;
  
  vec3 c1 = cos(vec3(s * n, n * n, d - s) * 8.0 - b) * 0.5 + 0.5;
  vec3 c2 = sin((vec3(s - b, -n, n)) * 6.0);
  vec3 c3 = sin(vec3(b, b, d) * 2.0 / (0.2 + l));

  vec4 textureColor = texture2D(gm_BaseTexture, vTexcoord);
  vec3 col = c1 * s;
  col += (1.0 - s) * c2 * smoothstep(0.2, 0.4, b * (1.1 - l * l));
  
  // can't decide which one of these is better
  col += mix((1.0 - l) * c3 * l, (0.8 - l) * c3 * l, l);
  //col += (1.0 - sqrt(l)) * c3;
  //col += (0.8 - l) * c3 * l;
  
  col = clamp(col, vec3(0), vec3(1));

  vec3 pixel = mix(col, textureColor.rgb, 0.17);
  gl_FragColor = vec4(
    pixel.x, 
    pixel.y, 
    pixel.z, 
    textureColor.a * vColor.a * ((pixel.x + pixel.y + pixel.z) / 1.33)
  );
}