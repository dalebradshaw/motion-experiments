#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>

// Vertex buffer indices
typedef enum LM_VertexInputIndex {
    LM_BVI_Vertices     = 0,
    LM_BVI_ViewportSize = 1,
} LM_VertexInputIndex;

// Texture indices
typedef enum LM_TextureIndex {
    LM_BTI_InputImage = 0,   // always: the source video frame
    LM_BTI_AuxImage   = 1,   // optional: env map / LUT / fringe map (image well)
} LM_TextureIndex;

// Fragment buffer indices
typedef enum LM_FragmentIndex {
    LM_BFI_Uniforms = 0,
} LM_FragmentIndex;

// Per-vertex data
typedef struct Vertex2D {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex2D;

// All shader uniforms — unused fields in a given shader are simply zero.
typedef struct LightingUniforms {
    int   shaderIndex;
    int   hasAuxTexture;    // 1 if an image well texture is bound at slot 1

    // Shared / Blinn / Phong / Hemisphere / EdgeFuzz / EnvMap light color
    float lightR, lightG, lightB;

    // Phong-specific
    float shininess, specular;
    float ambR, ambG, ambB;

    // Gooch
    float warmR, warmG, warmB;
    float coolR, coolG, coolB;
    float diffWarm, diffCool;

    // EdgeFuzz
    float edgeSpecularity, edgeFuzziness, edgeFade;
    float edgeColorR, edgeColorG, edgeColorB;
    float surfaceColorR, surfaceColorG, surfaceColorB;
    float ambientColorR, ambientColorG, ambientColorB;

    // GlossyWet
    float glossSpecExp, glossSpec;
    float glossMax, glossMin, glossDrop;
    float specColorR, specColorG, specColorB;
    float diffColorR, diffColorG, diffColorB;
    float glossAmbR,  glossAmbG,  glossAmbB;

    // LambSkin
    float lambRolloff;
    float lambAmbR, lambAmbG, lambAmbB;
    float lambDiffR, lambDiffG, lambDiffB;
    float lambSubR, lambSubG, lambSubB;

    // LUTSkin
    float lutDiffR, lutDiffG, lutDiffB;
    float lutSpecR, lutSpecG, lutSpecB;

    // ThinFilm
    float filmDepth;

    // EnvMap
    float envRatio;

    // Velvet
    float velvetRolloff;
    float velvetUnderR, velvetUnderG, velvetUnderB;

} LightingUniforms;

#endif /* ShaderTypes_h */
