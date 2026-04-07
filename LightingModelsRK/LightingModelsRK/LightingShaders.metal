/*
 LightingModelsRK.metal

 RealityKit CustomMaterial surface shaders — all 11 lighting models.
 Ported from LightingModels.metal (FxPlug screen-space) to RealityKit 3D surface shaders.

 Key differences from FxPlug version:
   - Real mesh normals via params.geometry().normal()
   - Real view direction via params.geometry().view_direction()
   - Parameters packed into custom_parameter (float4) + material_constants fields
   - Aux image texture accessed via params.textures().custom()
   - Each shader is a separate [[visible]] function, assigned per-material in Swift

 Parameter packing per shader (custom_parameter = float4(x,y,z,w)):
   Blinn:      custom = (lightR, lightG, lightB, _)
   Phong:      custom = (lightR, lightG, lightB, shininess)
               base_color_tint = (ambR, ambG, ambB)   roughness_scale = specular
   Gooch:      custom = (warmR, warmG, warmB, diffWarm)
               base_color_tint = (coolR, coolG, coolB) roughness_scale = diffCool
   EdgeFuzz:   custom = (edgeSpecularity, edgeFuzziness, edgeFade, _)
               base_color_tint = (lightR, lightG, lightB)
               emissive_color = (edgeColorR, edgeColorG, edgeColorB)
   GlossyWet:  custom = (glossSpecExp, glossSpec, glossDrop, _)
               base_color_tint = (specColorR, specColorG, specColorB)
               emissive_color = (diffColorR, diffColorG, diffColorB)
               roughness_scale = glossMax   metallic_scale = glossMin
   Hemisphere: custom = (skyR, skyG, skyB, _)
               base_color_tint = (groundR, groundG, groundB)
   LambSkin:   custom = (lambRolloff, lambDiffR, lambDiffG, lambDiffB)
               base_color_tint = (lambAmbR, lambAmbG, lambAmbB)
               emissive_color = (lambSubR, lambSubG, lambSubB)
   LUTSkin:    custom = (lutDiffR, lutDiffG, lutDiffB, _)  textures.custom() = LUT
               base_color_tint = (lutSpecR, lutSpecG, lutSpecB)
   ThinFilm:   custom = (filmDepth, _, _, _)               textures.custom() = fringe map
   EnvMap:     custom = (lightR, lightG, lightB, envRatio) textures.custom() = env image
   Velvet:     custom = (velvetRolloff, velvetUnderR, velvetUnderG, velvetUnderB)
*/

#include <RealityKit/RealityKit.h>
using namespace metal;

// Fixed light direction (upper-left)
constant float3 kLightDir = float3(-0.40825, 0.65560, 0.63246);

// GLSL lit() equivalent
inline float3 lit(float ndotl, float ndoth, float m) {
    float ambient  = 1.0;
    float diffuse  = max(ndotl, 0.0);
    float specular = step(0.0, ndotl) * pow(max(ndoth, 0.0), m);
    return float3(ambient, diffuse, specular);
}

// ─────────────────────────────────────────────────────────────────
// 0 — Blinn
// custom = (lightR, lightG, lightB, _)
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_blinn(realitykit::surface_parameters params) {
    float4 cp    = params.uniforms().custom_parameter();
    float3 N     = params.geometry().normal();
    float3 L     = kLightDir;
    float3 light = float3(cp.x, cp.y, cp.z);
    float  lam   = max(dot(N, L), 0.0f);
    params.surface().set_base_color(half3(light * lam));
    params.surface().set_roughness(1.0h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 1 — Phong Point Light
// custom = (lightR, lightG, lightB, shininess)
// base_color_tint = ambient color, roughness_scale = specular intensity
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_phong(realitykit::surface_parameters params) {
    float4 cp       = params.uniforms().custom_parameter();
    auto   mc       = params.material_constants();
    float3 N        = params.geometry().normal();
    float3 L        = kLightDir;
    float3 V        = params.geometry().view_direction();
    float3 light    = float3(cp.x, cp.y, cp.z);
    float  shine    = max(cp.w, 1.0);
    float3 ambient  = mc.base_color_tint();
    float  specInt  = mc.roughness_scale();

    float3 color = ambient;
    float  lam   = dot(N, L);
    if (lam > 0.0) {
        color += light * lam;
        float3 R   = reflect(-L, N);
        float  sp  = pow(max(dot(R, V), 0.0), shine);
        color += float3(1.0) * specInt * sp;
    }
    params.surface().set_base_color(half3(saturate(color)));
    params.surface().set_roughness(0.5h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 2 — Gooch
// custom = (warmR, warmG, warmB, diffWarm)
// base_color_tint = cool color, roughness_scale = diffCool
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_gooch(realitykit::surface_parameters params) {
    float4 cp      = params.uniforms().custom_parameter();
    auto   mc      = params.material_constants();
    float3 N       = params.geometry().normal();
    float3 L       = kLightDir;
    float3 V       = params.geometry().view_direction();

    float3 warm    = float3(cp.x, cp.y, cp.z);
    float  dWarm   = cp.w;
    float3 cool    = mc.base_color_tint();
    float  dCool   = mc.roughness_scale();

    float3 surf    = float3(0.5);
    float  NdotL   = (dot(L, N) + 1.0) * 0.5;
    float3 kcool   = min(cool  + dCool * surf, 1.0);
    float3 kwarm   = min(warm  + dWarm * surf, 1.0);
    float3 kfinal  = mix(kcool, kwarm, NdotL);
    float3 refl    = normalize(reflect(-L, N));
    float  spec    = pow(max(dot(refl, V), 0.0), 32.0);
    params.surface().set_base_color(half3(min(kfinal + spec, 1.0)));
    params.surface().set_roughness(0.8h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 3 — EdgeFuzz
// custom = (edgeSpecularity, edgeFuzziness, edgeFade, _)
// base_color_tint = light color,  emissive_color = edge color
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_edgefuzz(realitykit::surface_parameters params) {
    float4 cp      = params.uniforms().custom_parameter();
    auto   mc      = params.material_constants();
    float3 N       = params.geometry().normal();
    float3 L       = kLightDir;
    float3 V       = params.geometry().view_direction();
    float3 H       = normalize(V + L);

    float  edgeSpec  = cp.x;
    float  edgeFuzz  = cp.y;
    float  edgeFade  = cp.z;
    float3 lightC    = mc.base_color_tint();
    float3 edgeC     = mc.emissive_color();
    float3 surfC     = float3(0.7, 0.7, 0.7);
    float3 ambC      = float3(0.1, 0.1, 0.1);

    float  ldn   = dot(L, N);
    float3 litV  = lit(ldn, dot(H, N), edgeSpec);
    float  subd  = pow(abs(dot(N, V)), edgeFuzz);
    float3 SurfColor = mix(edgeC, surfC, subd);
    SurfColor        = mix(surfC, SurfColor, edgeFade);
    float  ldnC  = pow(max(ldn, 0.0), edgeFuzz);
    float3 incident  = mix(edgeC, lightC, ldnC);
    incident         = mix(lightC, incident, ldnC);
    float3 diff  = SurfColor * (litV.y * incident + ambC);
    float3 spec  = litV.y * litV.z * incident;
    params.surface().set_base_color(half3(saturate(diff + spec)));
    params.surface().set_roughness(0.6h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 4 — GlossyWet
// custom = (glossSpecExp, glossSpec, glossDrop, _)
// base_color_tint = spec color,  emissive_color = diff color
// roughness_scale = glossMax,  metallic_scale = glossMin
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_glossywet(realitykit::surface_parameters params) {
    float4 cp      = params.uniforms().custom_parameter();
    auto   mc      = params.material_constants();
    float3 N       = params.geometry().normal();
    float3 L       = kLightDir;
    float3 V       = params.geometry().view_direction();
    float3 H       = normalize(V + L);

    float  glossSpecExp = max(cp.x, 1.0);
    float  glossSpec    = cp.y;
    float  glossDrop    = cp.z;
    float3 specC    = mc.base_color_tint();
    float3 diffC    = mc.emissive_color();
    float  glossMax = mc.roughness_scale();
    float  glossMin = mc.metallic_scale();
    float3 ambC     = float3(0.1, 0.1, 0.1);

    float3 litV  = lit(dot(L, N), dot(H, N), glossSpecExp);
    float  spec  = litV.y * litV.z;
    float  gDrop = glossDrop + smoothstep(glossMin, glossMax, spec) * (1.0 - glossDrop);
    spec        *= glossSpec * gDrop;
    float3 specContrib = spec * specC;
    float3 diffContrib = litV.y * diffC + ambC;
    params.surface().set_base_color(half3(saturate(specContrib + diffContrib)));
    params.surface().set_roughness(0.2h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 5 — Hemisphere
// custom = (skyR, skyG, skyB, _)
// base_color_tint = ground color
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_hemisphere(realitykit::surface_parameters params) {
    float4 cp     = params.uniforms().custom_parameter();
    auto   mc     = params.material_constants();
    float3 N      = params.geometry().normal();
    float3 L      = kLightDir;
    float3 sky    = float3(cp.x, cp.y, cp.z);
    float3 ground = mc.base_color_tint();
    float  a      = 0.5 + 0.5 * dot(N, L);
    params.surface().set_base_color(half3(mix(ground, sky, a)));
    params.surface().set_roughness(1.0h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 6 — LambSkin
// custom = (lambRolloff, lambDiffR, lambDiffG, lambDiffB)
// base_color_tint = ambient color,  emissive_color = subsurface color
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_lambskin(realitykit::surface_parameters params) {
    float4 cp       = params.uniforms().custom_parameter();
    auto   mc       = params.material_constants();
    float3 N        = params.geometry().normal();
    float3 L        = kLightDir;

    float  rolloff  = cp.x;
    float3 diffC    = float3(cp.y, cp.z, cp.w);
    float3 ambC     = mc.base_color_tint();
    float3 subC     = mc.emissive_color();

    float  ldn      = dot(L, N);
    float3 diffuse  = max(0.0, ldn) * diffC;
    float  subLamb  = max(0.0, smoothstep(-rolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn));
    params.surface().set_base_color(half3(saturate(diffuse + ambC + subLamb * subC)));
    params.surface().set_roughness(0.9h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 7 — LUTSkin
// custom = (lutDiffR, lutDiffG, lutDiffB, _)   textures.custom() = Skin LUT
// base_color_tint = spec color
// With texture: sample LUT at (NdotL_remap, NdotH_remap)
// Without (custom returns 0,0,0,1): analytic fallback
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_lutskin(realitykit::surface_parameters params) {
    float4 cp       = params.uniforms().custom_parameter();
    auto   mc       = params.material_constants();
    float3 N        = params.geometry().normal();
    float3 L        = kLightDir;
    float3 V        = params.geometry().view_direction();
    float3 halfVec  = normalize(L + V);

    float3 diffC    = float3(cp.x, cp.y, cp.z);
    float3 specC    = mc.base_color_tint();

    float2 s;
    s.x = min(0.996, dot(N, L)       * 0.5 + 0.5);
    s.y =            dot(N, halfVec) * 0.5 + 0.5;

    constexpr sampler samp(address::clamp_to_edge, filter::linear);
    half4 texSample = params.textures().custom().sample(samp, s);

    float3 color;
    // custom() returns (0,0,0,1) when no texture assigned — detect by all-zero rgb
    if (texSample.r == 0.0h && texSample.g == 0.0h && texSample.b == 0.0h) {
        float3 lightVal = float3(s.x, s.x * s.x, pow(s.y, 4.0));
        color = diffC * lightVal + specC * pow(s.y, 8.0);
    } else {
        color = diffC * float3(texSample.rgb) + specC * pow(s.y, 8.0);
    }
    params.surface().set_base_color(half3(saturate(color)));
    params.surface().set_roughness(0.4h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 8 — ThinFilm
// custom = (filmDepth, _, _, _)   textures.custom() = fringe map
// With texture: sample fringe map at u = fract(viewDepth)
// Without: analytic rainbow
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_thinfilm(realitykit::surface_parameters params) {
    float4 cp        = params.uniforms().custom_parameter();
    float3 N         = params.geometry().normal();
    float3 L         = kLightDir;
    float3 V         = params.geometry().view_direction();
    float3 halfVec   = normalize(L + V);

    float  filmDepth = cp.x;
    float  viewDepth = (1.0 / max(dot(N, V), 0.001)) * filmDepth;
    float  diffuse   = max(dot(N, L), 0.0);
    float  spec      = pow(max(dot(N, halfVec), 0.0), 32.0);

    constexpr sampler samp(address::repeat, filter::linear);
    half4 texSample  = params.textures().custom().sample(samp, float2(fract(viewDepth), 0.5));

    float3 fringe;
    if (texSample.r == 0.0h && texSample.g == 0.0h && texSample.b == 0.0h) {
        fringe = float3(
            sin(viewDepth * 6.2831)         * 0.5 + 0.5,
            sin(viewDepth * 6.2831 + 2.094) * 0.5 + 0.5,
            sin(viewDepth * 6.2831 + 4.189) * 0.5 + 0.5);
    } else {
        fringe = float3(texSample.rgb);
    }
    float3 base = float3(0.5) * diffuse;
    params.surface().set_base_color(half3(saturate(base + fringe * spec)));
    params.surface().set_roughness(0.3h);
    params.surface().set_metallic(0.0h);
}

// ─────────────────────────────────────────────────────────────────
// 9 — EnvMap
// custom = (lightR, lightG, lightB, envRatio)   textures.custom() = env image
// With texture: equirect sample on reflection direction
// Without: procedural gradient env
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_envmap(realitykit::surface_parameters params) {
    float4 cp        = params.uniforms().custom_parameter();
    float3 N         = params.geometry().normal();
    float3 L         = kLightDir;
    float3 V         = params.geometry().view_direction();

    float3 light     = float3(cp.x, cp.y, cp.z);
    float  envRatio  = cp.w;

    float  diffLight = max(dot(L, N), 0.0);
    float3 outColor  = float3(0.1) + diffLight * light;
    float3 f         = reflect(-V, N);

    // Equirectangular projection of reflection vector
    constexpr sampler samp(address::clamp_to_edge, filter::linear);
    float phi        = atan2(f.z, f.x);
    float theta      = asin(clamp(f.y, -1.0, 1.0));
    float2 uv        = float2(phi / (2.0 * 3.14159265) + 0.5,
                              theta / 3.14159265 + 0.5);
    half4 texSample  = params.textures().custom().sample(samp, uv);

    float3 envColor;
    if (texSample.r == 0.0h && texSample.g == 0.0h && texSample.b == 0.0h) {
        envColor = float3(0.5 + 0.5 * f.x, 0.5 + 0.5 * f.y, 0.5 + 0.5 * f.z);
    } else {
        envColor = float3(texSample.rgb);
    }

    params.surface().set_base_color(half3(saturate(mix(outColor * float3(0.5), envColor, envRatio))));
    params.surface().set_roughness(0.1h);
    params.surface().set_metallic(0.3h);
}

// ─────────────────────────────────────────────────────────────────
// 10 — Velvet
// custom = (velvetRolloff, velvetUnderR, velvetUnderG, velvetUnderB)
// ─────────────────────────────────────────────────────────────────
[[visible]]
void shader_velvet(realitykit::surface_parameters params) {
    float4 cp      = params.uniforms().custom_parameter();
    float3 N       = params.geometry().normal();
    float3 L       = kLightDir;
    float3 V       = params.geometry().view_direction();

    float  rolloff  = cp.x;
    float3 under    = float3(cp.y, cp.z, cp.w);

    float  ldn      = dot(L, N);
    float3 diffuse  = max(0.0, ldn) * float3(0.6);
    float  subLamb  = max(0.0, smoothstep(-rolloff, 1.0, ldn) - smoothstep(0.0, 1.0, ldn));
    float  vdn      = 1.0 - dot(V, N);
    float3 spec     = float3(vdn);
    params.surface().set_base_color(half3(saturate(diffuse + subLamb * under + spec * 0.3)));
    params.surface().set_roughness(0.95h);
    params.surface().set_metallic(0.0h);
}
