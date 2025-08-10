#version 320 es
precision mediump float;

layout(location=0) uniform float uTime;
layout(location=1) uniform vec2 uMouse;
layout(location=2) uniform vec2 uResolution;

out vec4 fragColor;

float random(vec2 ab){ float f=cos(dot(ab,vec2(21.9898,78.233)))*43758.5453; return fract(f); }
float noise(vec2 xy){
    vec2 ij=floor(xy), uv=xy-ij; uv*=uv*(3.0-2.0*uv);
    float a=random(ij), b=random(ij+vec2(1,0)), c=random(ij+vec2(0,1)), d=random(ij+vec2(1,1));
    return a+(b-a)*uv.x+(c-a)*uv.y+(a-b-c+d)*uv.x*uv.y;
}

void main(){
    float iTime=uTime;
    vec2 fragCoord=gl_FragCoord.xy, resolution=uResolution;
    vec2 position=(fragCoord-0.5*resolution)/resolution.y;
    float color=pow(noise(fragCoord),40.0)*20.0;
    float r1=noise(fragCoord*noise(vec2(sin(iTime*0.01))));
    float r2=noise(fragCoord*noise(vec2(cos(iTime*0.01),sin(iTime*0.01))));
    float r3=noise(fragCoord*noise(vec2(sin(iTime*0.05),cos(iTime*0.05))));
    fragColor=vec4(color*r1, color*r2, color*r3, 1.0);
}
