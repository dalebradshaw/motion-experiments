/*
 LightingModels.metal

 All 11 lighting models from dalebradshaw/scenekit-lighting-models ported from GLSL to Metal.
 Each operates in screen-space on the FCP/Motion source video frame.

 Shader index:
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
// Vertex → rasterizer
// ─────────────────────────────────────────────────────────────────

struct RasterizerData {
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
};

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
// Helpers
// ─────────────────────────────────────────────────────────────────

// Reconstruct a hemisphere normal from UV
inline float3 uvNormal(float2 uv) {
    float2 n = uv * 2.0 - 1.0;
    float  z = sqrt(max(0.0, 1.0 - dot(n, n)));
    return normalize(float3(n, z));
}

// Fixed light direction (upper-left) — pre-computed literal, no global constructor
constant float3 kLightDir = float3(-0.40825, 0.65560, 0.63246);

// GLSL lit() equivalent
inline float3 lit(float ndotl, float ndoth, float m) {
    float ambient  = 1.0;
    float diffuse  = max(ndotl, 0.0);
    float specular = step(0.0, ndotl) * max(ndoth * m, 1.0);
    return float3(ambient, diffuse, specular);
}

// ─────────────────────────────────────────────────────────────────
// Per-shader implementations
// ─────────────────────────────────────────────────────────────────

// 0 — Blinn
float4 shader_blinn(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float4 lightColor = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float  lambert    = max(dot(N, L), 0.0);
    return lightColor * lambert * sample;
}

// 1 — Phong Point Light
float4 shader_phong(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 E = float3(0.0, 0.0, 1.0);
    float4 lightColor   = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float4 ambientColor = float4(u.ambR, u.ambG, u.ambB, 1.0);
    float4 matDiffuse   = float4(1.0, 1.0, 1.0, 1.0);
    float4 finalColor   = ambientColor;
    float  lambert = dot(N, L);
    if (lambert > 0.0) {
        finalColor += lightColor * matDiffuse * lambert;
        float3 R    = reflect(-L, N);
        float  spec = pow(max(dot(R, E), 0.0), u.shininess);
        finalColor += float4(1.0) * u.specular * spec;
    }
    return finalColor * sample;
}

// 2 — Gooch
float4 shader_gooch(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N      = uvNormal(uv);
    float3 L      = kLightDir;
    float3 V      = float3(0.0, 0.0, 1.0);
    float3 refl   = normalize(reflect(-L, N));
    float  NdotL  = (dot(L, N) + 1.0) * 0.5;
    float3 surface = sample.rgb;
    float3 kcool  = min(float3(u.coolR, u.coolG, u.coolB) + u.diffCool * surface, 1.0);
    float3 kwarm  = min(float3(u.warmR, u.warmG, u.warmB) + u.diffWarm * surface, 1.0);
    float3 kfinal = mix(kcool, kwarm, NdotL);
    float  spec   = pow(max(dot(refl, V), 0.0), 32.0);
    return float4(min(kfinal + spec, 1.0), 1.0);
}

// 3 — EdgeFuzz
float4 shader_edgefuzz(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 V = float3(0.0, 0.0, 1.0);
    float3 H = normalize(V + L);
    float  ldn  = dot(L, N);
    float3 litV = lit(ldn, dot(H, N), u.edgeSpecularity);
    float  subd = pow(abs(dot(N, V)), u.edgeFuzziness);
    float4 edgeColor    = float4(u.edgeColorR,    u.edgeColorG,    u.edgeColorB,    1.0);
    float4 surfaceColor = float4(u.surfaceColorR, u.surfaceColorG, u.surfaceColorB, 1.0);
    float4 lightColor   = float4(u.lightR,        u.lightG,        u.lightB,        1.0);
    float4 ambientColor = float4(u.ambientColorR, u.ambientColorG, u.ambientColorB, 1.0);
    float3 SurfColor    = mix(edgeColor.rgb, surfaceColor.rgb, subd);
    SurfColor           = mix(surfaceColor.rgb, SurfColor, u.edgeFade);
    float  ldnClamp     = pow(max(ldn, 0.0), u.edgeFuzziness);
    float3 incident     = mix(edgeColor.rgb, lightColor.rgb, ldnClamp);
    incident            = mix(lightColor.rgb, incident, ldnClamp);
    float3 diff = SurfColor * (litV.y * incident + ambientColor.rgb);
    float3 spec = litV.y * litV.z * incident;
    return float4(diff + spec, 1.0) * sample;
}

// 4 — GlossyWet
float4 shader_glossywet(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N = uvNormal(uv);
    float3 L = kLightDir;
    float3 V = float3(0.0, 0.0, 1.0);
    float3 H = normalize(V + L);
    float4 litV     = float4(lit(dot(L,N), dot(H,N), u.glossSpecExp), 1.0);
    float  spec     = litV.y * litV.z;
    float  gDrop    = u.glossDrop + smoothstep(u.glossMin, u.glossMax, spec) * (1.0 - u.glossDrop);
    spec            *= u.glossSpec * gDrop;
    float4 specContrib = spec * float4(u.specColorR, u.specColorG, u.specColorB, 1.0);
    float4 ambContrib  = float4(u.glossAmbR, u.glossAmbG, u.glossAmbB, 1.0);
    float4 diffContrib = litV.y * float4(u.diffColorR, u.diffColorG, u.diffColorB, 1.0) + ambContrib;
    return specContrib + diffContrib * sample;
}

// 5 — Hemisphere
float4 shader_hemisphere(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N      = uvNormal(uv);
    float3 L      = kLightDir;
    // lightR/G/B = sky color; ambR/G/B = ground color (packed by pluginState)
    float4 sky    = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float4 ground = float4(u.ambR,   u.ambG,   u.ambB,   1.0);
    float  a      = 0.5 + 0.5 * dot(N, L);
    return mix(ground, sky, a) * sample;
}

// 6 — LambSkin
float4 shader_lambskin(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N   = uvNormal(uv);
    float3 L   = kLightDir;
    float  ldn = dot(L, N);
    float4 ambient   = float4(u.lambAmbR,  u.lambAmbG,  u.lambAmbB,  1.0);
    float4 diffColor = float4(u.lambDiffR, u.lambDiffG, u.lambDiffB, 1.0);
    float4 subColor  = float4(u.lambSubR,  u.lambSubG,  u.lambSubB,  1.0);
    float4 diffuse   = max(0.0, ldn) * diffColor;
    float  subLamb   = max(0.0, smoothstep(-u.lambRolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn));
    return (diffuse + ambient + subLamb * subColor) * sample;
}

// 7 — LUTSkin
// Uses aux texture (SkinLUT) if available, otherwise analytic approximation
float4 shader_lutskin(float2 uv, float4 sample,
                      constant LightingUniforms &u,
                      texture2d<half> auxTex,
                      bool hasAux) {
    float3 N       = uvNormal(uv);
    float3 L       = kLightDir;
    float3 eye     = float3(0.0, 0.0, 1.0);
    float3 halfVec = normalize(L + eye);
    float2 s;
    s.x = min(0.996, dot(N, L)       * 0.5 + 0.5);
    s.y =            dot(N, halfVec) * 0.5 + 0.5;
    float4 diffColor = float4(u.lutDiffR, u.lutDiffG, u.lutDiffB, 1.0);
    float4 specColor = float4(u.lutSpecR, u.lutSpecG, u.lutSpecB, 1.0);
    if (hasAux) {
        constexpr sampler luts(mag_filter::linear, min_filter::linear);
        float4 lut = float4(auxTex.sample(luts, s));
        return diffColor * lut + specColor * lut.a;
    } else {
        float3 lightVal = float3(s.x, s.x * s.x, pow(s.y, 4.0));
        return diffColor * float4(lightVal, 1.0) * sample + specColor * pow(s.y, 8.0);
    }
}

// 8 — ThinFilm
// Uses aux texture (FringeMap) if available, otherwise analytic rainbow
float4 shader_thinfilm(float2 uv, float4 sample,
                       constant LightingUniforms &u,
                       texture2d<half> auxTex,
                       bool hasAux) {
    float3 N       = uvNormal(uv);
    float3 eye     = float3(0.0, 0.0, 1.0);
    float3 L       = kLightDir;
    float3 halfVec = normalize(L + eye);
    float  viewDepth = (1.0 / max(dot(N, eye), 0.001)) * u.filmDepth;
    float  diffuse   = max(dot(N, L), 0.0);
    float  spec      = pow(max(dot(N, halfVec), 0.0), 32.0);
    float3 fringe;
    if (hasAux) {
        constexpr sampler fs(mag_filter::linear, min_filter::linear, address::repeat);
        float2 fringeUV = float2(fmod(viewDepth, 1.0), 0.5);
        fringe = float3(auxTex.sample(fs, fringeUV).rgb);
    } else {
        fringe = float3(
            sin(viewDepth * 6.2831)         * 0.5 + 0.5,
            sin(viewDepth * 6.2831 + 2.094) * 0.5 + 0.5,
            sin(viewDepth * 6.2831 + 4.189) * 0.5 + 0.5);
    }
    return float4(diffuse * sample.rgb + fringe * spec, 1.0);
}

// 9 — EnvMap
// Uses aux texture (environment image) if available
float4 shader_envmap(float2 uv, float4 sample,
                     constant LightingUniforms &u,
                     texture2d<half> auxTex,
                     bool hasAux) {
    float3 N  = uvNormal(uv);
    float3 V  = float3(0.0, 0.0, 1.0);
    float3 L  = kLightDir;
    float4 diffuse  = float4(u.lightR, u.lightG, u.lightB, 1.0);
    float  diffLight = max(dot(L, N), 0.0);
    float4 outColor  = float4(0.1, 0.1, 0.1, 1.0) + diffLight * diffuse;
    float3 f = reflect(-V, N);
    float4 envColor;
    if (hasAux) {
        constexpr sampler es(mag_filter::linear, min_filter::linear);
        float m = 2.0 * sqrt(f.x*f.x + f.y*f.y + (f.z+1.0)*(f.z+1.0));
        float2 envUV = float2(f.x/m + 0.5, -f.y/m + 0.5);
        envColor = float4(auxTex.sample(es, envUV));
    } else {
        envColor = sample; // use source frame as cheap stand-in
    }
    return mix(outColor * sample, envColor, u.envRatio);
}

// 10 — Velvet
float4 shader_velvet(float2 uv, float4 sample, constant LightingUniforms &u) {
    float3 N   = uvNormal(uv);
    float3 L   = kLightDir;
    float3 V   = float3(0.0, 0.0, 1.0);
    float4 under = float4(u.velvetUnderR, u.velvetUnderG, u.velvetUnderB, 1.0);
    float  ldn       = dot(L, N);
    float  diffComp  = max(0.0, ldn);
    float4 diffContrib = diffComp * sample;
    float  subLamb   = max(0.0, smoothstep(-u.velvetRolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn));
    float4 subContrib  = subLamb * under;
    float  vdn = 1.0 - dot(V, N);
    float4 specContrib = float4(vdn, vdn, vdn, 1.0);
    return diffContrib + subContrib + specContrib;
}

// ─────────────────────────────────────────────────────────────────
// Fragment shader — dispatches to selected lighting model
// ─────────────────────────────────────────────────────────────────

fragment float4 fragmentShader(
    RasterizerData            in         [[stage_in]],
    texture2d<half>           colorTex   [[texture(LM_BTI_InputImage)]],
    texture2d<half>           auxTex     [[texture(LM_BTI_AuxImage)]],
    constant LightingUniforms &uniforms  [[buffer(LM_BFI_Uniforms)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float4 sample = float4(colorTex.sample(s, in.textureCoordinate));
    float2 uv     = in.textureCoordinate;
    bool   hasAux = uniforms.hasAuxTexture != 0;

    switch (uniforms.shaderIndex) {
        case 0:  return shader_blinn     (uv, sample, uniforms);
        case 1:  return shader_phong     (uv, sample, uniforms);
        case 2:  return shader_gooch     (uv, sample, uniforms);
        case 3:  return shader_edgefuzz  (uv, sample, uniforms);
        case 4:  return shader_glossywet (uv, sample, uniforms);
        case 5:  return shader_hemisphere(uv, sample, uniforms);
        case 6:  return shader_lambskin  (uv, sample, uniforms);
        case 7:  return shader_lutskin   (uv, sample, uniforms, auxTex, hasAux);
        case 8:  return shader_thinfilm  (uv, sample, uniforms, auxTex, hasAux);
        case 9:  return shader_envmap    (uv, sample, uniforms, auxTex, hasAux);
        case 10: return shader_velvet    (uv, sample, uniforms);
        default: return sample;
    }
}
