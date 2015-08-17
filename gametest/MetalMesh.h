//
//  MetalMesh.h
//  gametest
//
//  Created by Prabhat Godse on 8/16/15.
//  Copyright © 2015 Prabhat Godse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MetalMesh : NSObject

- (id)initMeshWithDevice:(id<MTLDevice>)device;

- (void)createBoxGeometry:(float)length;

- (void)drawObjectWithCommandEncoder:(id <MTLRenderCommandEncoder>)commandEncoder;
@end
