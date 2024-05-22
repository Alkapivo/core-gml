///@description https://www.shadertoy.com/view/M3tGWr
///@author ProfessorPixels 2024-05-22
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 iResolution;
uniform float iTime;
uniform float size;
uniform float amount;

#define t 6.28318530718
#define r 6.

vec3 g(vec3 a, vec3 b, float n) {
    vec3 aa = a*n;
    vec3 bb = b*(1.-n);
    return aa+bb;
}

float SDFhex(vec2 p) {
    float L = length(p);
    return L+(L*.034*cos(6.*atan(p.y,p.x)));
}

vec2 R(vec2 p) {
    vec2 sc = vec2(sin(iTime),cos(iTime));
    return vec2((p.x*sc.y)-(p.y*sc.x),(p.x*sc.x)+(p.y*sc.y));
}

void main() {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 h = iResolution.xy * amount;
    vec2 uv = R(v_vTexcoord - h) / size;
    // Time varying pixel color
    float s = SDFhex(uv);
    float c = fract(s-iTime*.5);
    vec3 col = vec3(g(vec3(.48,0.,1.),vec3(.3,0.,0.85),sqrt(c)));
    //if (s>r) col = vec3(0.);
    
    // Output to screen
    gl_FragColor = vec4(col,v_vColour.a);
}
