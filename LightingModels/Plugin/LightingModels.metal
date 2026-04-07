/*
 LightingModels.metal
 
 All 11 lighting models from dalebradshaw/scenekit-lighting-models ported from GLSL to Metal.
 Each is implemented as a pure image-processing effect applied to the FCP/Motion source frame.
 
 Because FxTileableEffect receives a 2D video frame (not 3D geometry), these shaders operate in
 screen-space: UV coordinates drive the lighting math so the effect looks like a stylised
 colour-grade / look rather than a geometry shader.  This is the correct interpretation for a
 video filter — the same approach used by all built-in FCP colour effects.
 
 Shader index mapping (matches ShaderID enum in PlugIn.swift):
   0  Blinn            5  Hemisphere
   1  Phong Point      6  LambSkin
   2  Gooch            7  LUTSkin
   3  EdgeFuzz         8  ThinFilm
   4  GlossyWet        9  EnvMap
                      10  Velvet
*/

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
#include "ShaderTypes.h"

// ─────────────────────────────────────────────────────────────────
// Shared vertex → rasterizer data
// ─────────────────────────────────────────────────────────────────

struct RasterizerData {
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
};

// ─────────────────────────────────────────────────────────────────
// Vertex shader — identical for every lighting model
// ─────────────────────────────────────────────────────────────────

vertex RasterizerData vertexShader(
    uint                          vertexID        [[vertex_id]],
    constant Vertex2D            *vertexArray     [[buffer(LM_BVI_Vertices)]],
    constant vector_uint2        *viewportSizePtr [[buffer(LM_BVI_ViewportSize)]])
{
    RasterizerData out;
    float2 pixelPos  = vertexArray[vertexID].position;
    float2 vpSize    = float2(*viewportSizePtr);
    out.clipSpacePosition = float4(pixelPos / (vpSize * 0.5), 0.0, 1.0);
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// ─────────────────────────────────────────────────────────────────
// Helpers shared across shaders
// ─────────────────────────────────────────────────────────────────

// Reconstruct a "normal" from UV for screen-space shading.
// UV (0,0)→(1,1) is mapped to a hemisphere normal pointing outward.
inline float3 uvNormal(float2 uv) {
    float2 n = uv * 2.0 - 1.0;
    float  z = sqrt(max(0.0, 1.0 - dot(n, n)));
    return normalize(float3(n, z));
}

// Fixed light direction (upper-left in UV space) — pre-normalised literal, no global constructor
constant float3 kLightDir = float3(-0.40825, 0.65560, 0.63246);

// GLSL lit() equivalent
inline float3 lit(float ndotl, float ndoth, float m) {
    float ambient  = 1.0;
    float diffuse  = max(ndotl, 0.0);
    float specular = step(0.0, ndotl) * max(ndoth * m, 1.0);
    return float3(ambient, diffuse, specular);
}

// ─────────────────────────────────────────────────────────────────
// Per-shader implementations (all take UV + sample + uniforms)
// ─────────────────────────────────────────────────────────────────

// 0 — Blinn
float4 shader_blinn(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float4 lightColor    = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float4 lightAmbient  = float4(0.0, 0.0, 0.0, 1.0);
    float4 matDiffuse    = float4(1.0, 1.0, 1.0, 1.0);
    float4 matAmbient    = float4(0.0, 0.0, 0.0, 1.0);
    float  lambert = dot(N, L);
    float4 color = matAmbient * lightAmbient;
    if (lambert > 0.0)
        color += lightColor * matDiffuse * lambert;
    return color * sample;
}

// 1 — Phong Point Light
float4 shader_phong(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 E = normalize(float3(0.0, 0.0, 1.0));
    float4 lightColor   = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float4 lightAmbient = float4(u.ambR, u.ambG, u.ambB, 1.0);
    float4 matDiffuse   = float4(1.0, 1.0, 1.0, 1.0);
    float4 matAmbient   = float4(0.0, 0.0, 0.0, 1.0);
    float4 matEmission  = float4(0.0, 0.0, 0.0, 1.0);
    float4 sceneColor   = matEmission + matAmbient * lightAmbient;
    float4 finalColor   = sceneColor * matAmbient + lightAmbient * matAmbient;
    float  lambert = dot(N, L);
    if (lambert > 0.0) {
        finalColor += lightColor * matDiffuse * lambert;
        float3 R = reflect(-L, N);
        float  spec = pow(max(dot(R, E), 0.0), u.shininess);
        finalColor += float4(1.0) * u.specular * spec;
    }
    return finalColor * sample;
}

// 2 — Gooch
float4 shader_gooch(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N       = uvNormal(uv);
    float3 L       = kLightDir;
    float3 V       = normalize(float3(0.0, 0.0, 1.0));
    float3 reflect_ = normalize(reflect(-L, N));
    float  NdotL   = (dot(L, N) + 1.0) * 0.5;
    float3 surface = sample.rgb;
    float3 kcool   = min(float3(u.coolR, u.coolG, u.coolB) + u.diffCool * surface, 1.0);
    float3 kwarm   = min(float3(u.warmR, u.warmG, u.warmB) + u.diffWarm * surface, 1.0);
    float3 kfinal  = mix(kcool, kwarm, NdotL);
    float  spec    = pow(max(dot(reflect_, V), 0.0), 32.0);
    return float4(min(kfinal + spec, 1.0), 1.0);
}

// 3 — EdgeFuzz
float4 shader_edgefuzz(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 V = normalize(float3(0.0, 0.0, 1.0));
    float3 H = normalize(V + L);
    float  ldn  = dot(L, N);
    float3 litV = lit(ldn, dot(H, N), u.edgeSpecularity);
    float  subd = abs(dot(N, V));
    subd = pow(subd, u.edgeFuzziness);
    float4 edgeColor    = float4(0.0, 0.0, 0.0, 1.0);
    float4 surfaceColor = sample;
    float4 lightColor   = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float4 ambientColor = float4(0.1, 0.1, 0.1, 1.0);
    float3 SurfColor = mix(edgeColor.rgb, surfaceColor.rgb, subd);
    SurfColor = mix(surfaceColor.rgb, SurfColor, u.edgeFade);
    float  ldnClamped = pow(max(ldn, 0.0), u.edgeFuzziness);
    float3 incidentColor = mix(edgeColor.rgb, lightColor.rgb, ldnClamped);
    incidentColor = mix(lightColor.rgb, incidentColor, ldnClamped);
    float3 diff = SurfColor * (litV.y * incidentColor + ambientColor.rgb);
    float3 spec = litV.y * litV.z * incidentColor;
    return float4(diff + spec, 1.0);
}

// 4 — GlossyWet
float4 shader_glossywet(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 V = normalize(float3(0.0, 0.0, 1.0));
    float3 H = normalize(V + L);
    float4 litV = float4(lit(dot(L,N), dot(H,N), u.glossSpecExp), 1.0);
    float  spec = litV.y * litV.z;
    float  glossDrop = u.glossDrop + smoothstep(u.glossMin, u.glossMax, spec) * (1.0 - u.glossDrop);
    spec *= u.glossSpec * glossDrop;
    float4 specContrib  = spec * float4(1.0, 1.0, 1.0, 1.0);
    float4 diffContrib  = litV.y * sample + float4(0.05, 0.05, 0.05, 1.0);
    return specContrib + diffContrib;
}

// 5 — Hemisphere
float4 shader_hemisphere(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float4 skyColor    = float4(u.lightR, u.lightG, u.lightB + 0.3, 1.0);
    float4 groundColor = float4(u.lightR * 0.3, u.lightG * 0.3, u.lightB * 0.3, 1.0);
    float costheta = dot(N, L);
    float a = 0.5 + 0.5 * costheta;
    float4 hemi = mix(groundColor, skyColor, a);
    return hemi * sample;
}

// 6 — LambSkin
float4 shader_lambskin(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float  ldn = dot(normalize(L), N);
    float  diffComp = max(0.0, ldn);
    float4 diffuse    = float4(diffComp * sample.rgb, 1.0);
    float4 ambient    = float4(0.05, 0.05, 0.05, 1.0);
    float4 subColor   = float4(u.lightR * 0.6, u.lightG * 0.2, u.lightB * 0.2, 1.0);
    float  subLamb = smoothstep(-u.lambRolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn);
    subLamb = max(0.0, subLamb);
    float4 subsurface = subLamb * subColor;
    return diffuse + ambient + subsurface;
}

// 7 — LUTSkin (no actual LUT texture available in a video filter; approximates with analytic curve)
float4 shader_lutskin(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N       = uvNormal(uv);
    float3 L       = kLightDir;
    float3 eye     = float3(0.0, 0.0, 1.0);
    float3 halfVec = normalize(L + eye);
    float2 s;
    s.x = dot(N, L) * 0.5 + 0.5;
    s.y = dot(N, halfVec) * 0.5 + 0.5;
    s.x = min(0.996, s.x);
    // Analytic skin LUT approximation
    float4 diffuseColor  = sample;
    float4 specularColor = float4(0.8, 0.7, 0.6, 1.0);
    float3 lightVal = float3(s.x, s.x * s.x, pow(s.y, 4.0));
    return diffuseColor * float4(lightVal, 1.0) + specularColor * pow(s.y, 8.0);
}

// 8 — ThinFilm
float4 shader_thinfilm(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N       = uvNormal(uv);
    float3 eye     = float3(0.0, 0.0, 1.0);
    float3 L       = kLightDir;
    float3 halfVec = normalize(L + eye);
    float  viewDepth = (1.0 / max(dot(N, eye), 0.001)) * u.filmDepth;
    float  diffuse = max(dot(N, L), 0.0);
    float  specular = pow(max(dot(N, halfVec), 0.0), 32.0);
    // Fringe colour from thin-film interference (analytic rainbow)
    float3 fringe = float3(
        sin(viewDepth * 6.2831) * 0.5 + 0.5,
        sin(viewDepth * 6.2831 + 2.094) * 0.5 + 0.5,
        sin(viewDepth * 6.2831 + 4.189) * 0.5 + 0.5);
    return float4(diffuse * sample.rgb + fringe * specular, 1.0);
}

// 9 — EnvMap (spherical env-map from UV reflection)
float4 shader_envmap(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N      = uvNormal(uv);
    float3 V      = normalize(float3(0.0, 0.0, 1.0));
    float3 L      = kLightDir;
    float4 ambient  = float4(0.1, 0.1, 0.1, 1.0);
    float4 diffuse  = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float  diffLight = max(dot(L, N), 0.0);
    float4 outColor = ambient + diffLight * diffuse;
    // Env map coord from reflection
    float3 f = reflect(-V, N);
    float  m = 2.0 * sqrt(f.x*f.x + f.y*f.y + (f.z + 1.0)*(f.z + 1.0));
    // env map UV (used as passthrough re-sample of input — bind a real env texture for production)
    float2 _envUV = float2(f.x/m + 0.5, -f.y/m + 0.5); (void)_envUV;
    // Re-sample input as a cheap stand-in for an env map
    // (In a real pipeline you'd bind a dedicated env texture)
    float4 envColor = sample; // placeholder
    return mix(outColor * sample, envColor, u.envRatio);
}

// 10 — Velvet
float4 shader_velvet(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N  = uvNormal(uv);
    float3 L  = kLightDir;
    float3 V  = normalize(float3(0.0, 0.0, 1.0));
    float4 primary  = sample;                           // diffuse
    float4 fuzz     = float4(1.0, 1.0, 1.0, 1.0);      // specular highlight
    float4 under    = float4(u.lightR * 0.4, u.lightG * 0.2, u.lightB * 0.2, 1.0);
    float  ldn = dot(L, N);
    float  diffComp = max(0.0, ldn);
    float4 diffContrib = diffComp * primary;
    float  subLamb = smoothstep(-u.velvetRolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn);
    subLamb = max(0.0, subLamb);
    float4 subContrib = subLamb * under;
    float  vdn = 1.0 - dot(V, N);
    float4 specContrib = float4(vdn, vdn, vdn, 1.0) * fuzz;
    return diffContrib + subContrib + specContrib;
}

// ─────────────────────────────────────────────────────────────────
// Fragment shader — dispatches to the selected lighting model
// ─────────────────────────────────────────────────────────────────

fragment float4 fragmentShader(
    RasterizerData           in          [[stage_in]],
    texture2d<half>          colorTex    [[texture(LM_BTI_InputImage)]],
    constant LightingUniforms &uniforms  [[buffer(LM_BFI_Uniforms)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float4 sample = float4(colorTex.sample(s, in.textureCoordinate));
    float2 uv     = in.textureCoordinate;

    switch (uniforms.shaderIndex) {
        case 0:  return shader_blinn     (uv, sample, uniforms);
        case 1:  return shader_phong     (uv, sample, uniforms);
        case 2:  return shader_gooch     (uv, sample, uniforms);
        case 3:  return shader_edgefuzz  (uv, sample, uniforms);
        case 4:  return shader_glossywet (uv, sample, uniforms);
        case 5:  return shader_hemisphere(uv, sample, uniforms);
        case 6:  return shader_lambskin  (uv, sample, uniforms);
        case 7:  return shader_lutskin   (uv, sample, uniforms);
        case 8:  return shader_thinfilm  (uv, sample, uniforms);
        case 9:  return shader_envmap    (uv, sample, uniforms);
        case 10: return shader_velvet    (uv, sample, uniforms);
        default: return sample;
    }
}
