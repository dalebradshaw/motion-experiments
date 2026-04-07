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
    LM_BTI_InputImage = 0,
} LM_TextureIndex;

// Fragment buffer indices
typedef enum LM_FragmentIndex {
    LM_BFI_Uniforms = 0,
} LM_FragmentIndex;

// Per-vertex data (matches template)
typedef struct Vertex2D {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex2D;

// All shader uniforms in one struct — zero-cost fields that aren't
// used by the selected shader are simply ignored in the Metal code.
typedef struct LightingUniforms {
    int   shaderIndex;

    // Shared light color
    float lightR, lightG, lightB;

    // Phong
    float shininess, specular;
    float ambR, ambG, ambB;

    // Gooch
    float warmR, warmG, warmB;
    float coolR, coolG, coolB;
    float diffWarm, diffCool;

    // EdgeFuzz
    float edgeSpecularity, edgeFuzziness, edgeFade;

    // GlossyWet
    float glossSpecExp, glossSpec;
    float glossMax, glossMin, glossDrop;

    // LambSkin
    float lambRolloff;

    // ThinFilm
    float filmDepth;

    // EnvMap
    float envRatio;

    // Velvet
    float velvetRolloff;
} LightingUniforms;

#endif /* ShaderTypes_h */
