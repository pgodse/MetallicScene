//
//  MetalMesh.m
//  gametest
//
//  Created by Prabhat Godse on 8/16/15.
//  Copyright © 2015 Prabhat Godse. All rights reserved.
//

#import "MetalMesh.h"

#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>
#import "SharedStructures.h"

@implementation MetalMesh {
    id<MTLDevice> _device;
    NSUInteger _vertexCount;
    id <MTLBuffer> _meshBuffer;
    id <MTLBuffer> _colorBuffer;
}

- (id)initMeshWithDevice:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        _device = device;
        _vertexCount = 0;
    }
    return self;
}

- (void)createBoxGeometry:(float)length {
    _vertexCount = 36;
    vector_float3 a = {-length, -length, length};
    vector_float3 b = {length, -length, length};
    vector_float3 c = {length, length, length};
    vector_float3 d = {-length, length, length};
    
    vector_float3 e = {-length, -length, -length};
    vector_float3 f = {length, -length, -length};
    vector_float3 g = {length, length, -length};
    vector_float3 h = {-length, length, -length};
    
    Triangle boxes[36] = {
        e, a, f,    f, a, b,
        h, d, c,    g, h, c,
        c, a, b,    c, d, a,
        g, f, h,    h, f, e,
        h, e, d,    d, e, a,
        g, c, b,    g, b, f
    };
    
    _meshBuffer = [_device newBufferWithBytes:&boxes
                                       length:sizeof(Triangle[_vertexCount])
                                      options:MTLResourceOptionCPUCacheModeDefault];
    [_meshBuffer setLabel:@"MyBox"];
    
    PointColor colors[3] = {
        (vector_float4) {0.6, 0.4, 0.4, 1.0},
        (vector_float4) {0.6, 0.4, 0.5, 1.0},
        (vector_float4) {0.6, 0.7, 0.4, 1.0}
    };
    _colorBuffer = [_device newBufferWithBytes:&colors
                                        length:sizeof(PointColor[3])
                                       options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)drawObjectWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder {
    [commandEncoder setVertexBuffer:_meshBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:_colorBuffer offset:0 atIndex:2];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_vertexCount];
}
@end
