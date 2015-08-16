//
//  MyShader.metal
//  MetalTutorial
//
//  Created by Orlando Pereira on 20/08/14.
//  Copyright (c) 2014 RokkittGames. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct {
    float3 position;
} Triangle;

typedef struct {
    float4 color;
}PointColor;

typedef struct {
    float4 position [[position]];
    float4 color;
} TriangleOutput;

typedef struct __attribute__((__aligned__(256)))
{
    matrix_float4x4 modelview_projection_matrix;
    matrix_float4x4 normal_matrix;
} uniforms_t;


vertex TriangleOutput VertexColor(const device Triangle *Vertices [[buffer(0)]], const uint index [[vertex_id]],
                                  constant uniforms_t& uniform[[buffer(1)]],
                                  const device PointColor* color [[buffer(2)]])
{
    TriangleOutput out;
    out.position = uniform.modelview_projection_matrix * float4(Vertices[index].position, 1.0);
//    out.color = color[index].color;
    out.color = float4(Vertices[index].position.x, Vertices[index].position.y, Vertices[index].position.z, 1.0);
    return out;
}

fragment float4 FragmentColor(TriangleOutput in [[stage_in]]) {
    return in.color;
//    return float4(1.0, 0.0, 0.0, 1.0);
}