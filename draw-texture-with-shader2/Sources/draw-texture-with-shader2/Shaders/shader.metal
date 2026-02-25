//
//  shader.metal
//  draw-texture-with-shader
//
//  Created by mtakagi on 2026/02/26.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float2 texCoords;
};

vertex Vertex vertex_function(constant float4* positions [[buffer(0)]],
                              constant float2* texCoords [[buffer(1)]],
                              uint vid [[vertex_id]]) {
    Vertex out;
    out.position = positions[vid];
    out.texCoords = texCoords[vid];
    return out;
}

fragment float4 fragment_function(Vertex in [[stage_in]], texture2d<float> texture [[texture(0)]]) {
    constexpr sampler sampler;
    
    return texture.sample(sampler, in.texCoords);
}
