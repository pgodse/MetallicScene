//
//  GameViewController.m
//  gametest
//
//  Created by Prabhat Godse on 8/15/15.
//  Copyright (c) 2015 Prabhat Godse. All rights reserved.
//

#import "GameViewController.h"
#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>
#import "SharedStructures.h"

#import "MetalMesh.h"

// The max number of command buffers in flight
static const NSUInteger kMaxInflightBuffers = 3;

// Max API memory buffer size.
static const size_t kMaxBytesPerFrame = 1024*1024;

@implementation GameViewController
{
    // view
    MTKView *_view;
    
    // controller
    dispatch_semaphore_t _inflight_semaphore;
    id <MTLBuffer> _dynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;
    
    // renderer
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    
    // uniforms
    matrix_float4x4 _projectionMatrix;
    matrix_float4x4 _viewMatrix;
    uniforms_t _uniform_buffer;
    float _rotation;
    
    // meshes
    MTKMesh *_boxMesh;
    
    MTLRenderPipelineDescriptor *renderPipelineDescriptor;
//    id <MTLBuffer> object;
//    id <MTLBuffer> _colorBuffer;
    
//    NSUInteger _vertexCount;
    
    MetalMesh *_sampleMesh;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _constantDataBufferIndex = 0;
    _inflight_semaphore = dispatch_semaphore_create(3);
    
    [self _setupMetal];
    [self _setupView];
    
    // Create a reusable pipeline state
    renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = _view.colorPixelFormat;
    renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
    renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;
    renderPipelineDescriptor.sampleCount = _view.sampleCount;
    _view.clearColor = MTLClearColorMake(0.5, 0.3, 0.1, 1.0);
    
    // shaders
    id <MTLLibrary> lib = [_device newDefaultLibrary];
    renderPipelineDescriptor.vertexFunction = [lib newFunctionWithName:@"VertexColor"];
    renderPipelineDescriptor.fragmentFunction = [lib newFunctionWithName:@"FragmentColor"];
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error: nil];
    
    _sampleMesh = [[MetalMesh alloc] initMeshWithDevice:_device];
    [_sampleMesh createBoxGeometry:1.0];
    
    _uniform_buffer.ambientColor = (vector_float3){0.2, 0.2, 0.2};
    
    _dynamicConstantBuffer = [_device newBufferWithBytes:&_uniform_buffer length:sizeof(uniforms_t) options:MTLResourceOptionCPUCacheModeDefault];
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
}

-(void)renderSceneCustom
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    [self _update];
    
    // Create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor* renderPassDescriptor = _view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor == nil)
        return;
    
    // Create a render command encoder so we can render into something
//    id<MTLParallelRenderCommandEncoder> parallel = [commandBuffer parallelRenderCommandEncoderWithDescriptor:renderPassDescriptor];
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    [renderEncoder setDepthStencilState:_depthState];
    
    // Set context state
    [renderEncoder pushDebugGroup:@"DrawCube"];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setVertexBuffer:_dynamicConstantBuffer offset:0 atIndex:1];
    [_sampleMesh drawObjectWithCommandEncoder:renderEncoder];
    [renderEncoder popDebugGroup];
    
    // We're done encoding commands
    [renderEncoder endEncoding];
    
//    [renderEncoder2 endEncoding];
//    [parallel endEncoding];
    // Call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    // The renderview assumes it can now increment the buffer index and that the previous index won't be touched until we cycle back around to the same index
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kMaxInflightBuffers;
    
    // Schedule a present once the framebuffer is complete using the current drawable
    [commandBuffer presentDrawable:_view.currentDrawable];
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)_setupView
{
    _view = (MTKView *)self.view;
    _view.delegate = self;
    _view.device = _device;
    _view.preferredFramesPerSecond = 60;
    // Setup the render target, choose values based on your app
    _view.sampleCount = 4;
    _view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
}

- (void)_setupMetal
{
    // Set the view to use the default device
    _device = MTLCreateSystemDefaultDevice();

    // Create a new command queue
    _commandQueue = [_device newCommandQueue];
    
    // Load all the shader files with a metal file extension in the project
    _defaultLibrary = [_device newDefaultLibrary];
}


- (void)_loadAssets44
{
    id tt = [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
}


- (void)_reshape
{
    // When reshape is called, update the view and projection matricies since this means the view orientation or size changed
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    _projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
    
    _viewMatrix = matrix_identity_float4x4;
}

- (void)_update
{
    matrix_float4x4 base_model = matrix_multiply(matrix_from_translation(0.0f, 0.0f, 5.0f), matrix_from_rotation(_rotation, 0.0f, 1.0f, 0.0f));
    matrix_float4x4 base_mv = matrix_multiply(_viewMatrix, base_model);
    matrix_float4x4 modelViewMatrix = matrix_multiply(base_mv, matrix_from_rotation(_rotation, 1.0f, 1.0f, 1.0f));
    
    // Load constant buffer data into appropriate buffer at current index
    uniforms_t *uniforms = &((uniforms_t *)[_dynamicConstantBuffer contents])[0];
    uniforms->normal_matrix = matrix_invert(matrix_transpose(modelViewMatrix));
    uniforms->modelview_projection_matrix = matrix_multiply(_projectionMatrix, modelViewMatrix);
    
    //Triangle *tr = &[object contents][0];
//    tr->position.s = 3 * sin(_rotation);
//    PointColor *color = &[_colorBuffer contents][0];
//    color->colorRGB =  cos(_rotation);
    _rotation += 0.01f;
}

// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    //[self _reshape];
}


// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView *)view
{
    @autoreleasepool {
        [self renderSceneCustom];
        //[self _render];
    }
}

- (void)view:(id)a1 willLayoutWithSize:(CGSize)size {
    [self _reshape];
}

- (void)drawInView:(id)view {
    [self drawInMTKView:view];
}

#pragma mark Utilities

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ)
{
    float yscale = 1.0f / tanf(fovY * 0.5f); // 1 / tan == cot
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);
    
    matrix_float4x4 m = {
        .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, q, 1.0f },
        .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
    };
    
    return m;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z)
{
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4) { x, y, z, 1.0 };
    return m;
}

static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z)
{
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);
    matrix_float4x4 m = {
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },
        
        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },
        
        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },
        
        .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
        }
    };
    return m;
}

@end
