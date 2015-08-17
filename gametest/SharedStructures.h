//
//  SharedStructures.h
//  gametest
//
//  Created by Prabhat Godse on 8/15/15.
//  Copyright (c) 2015 Prabhat Godse. All rights reserved.
//

#ifndef SharedStructures_h
#define SharedStructures_h

#include <simd/simd.h>
//#include <GLKit/GLKit.h>

typedef struct {
    vector_float3 position;
}Triangle;

typedef struct {
    vector_float4 colorRGB;
} PointColor;

typedef struct __attribute__((__aligned__(256)))
{
    matrix_float4x4 modelview_projection_matrix;
    matrix_float4x4 normal_matrix;
    vector_float3 ambientColor;
} uniforms_t;

#endif /* SharedStructures_h */

