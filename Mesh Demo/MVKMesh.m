//
//  MVKMesh.m
//  Mesh Demo
//
//  Created by Hal Mueller on 5/26/15.
//  Copyright (c) 2015 UW GeoClaw. All rights reserved.
//

#import "MVKMesh.h"
@import GLKit;

@interface MVKMesh ()
@property (nonatomic, strong) SCNGeometry *geometry;
@end

@implementation MVKMesh

- (id)initWithMultiplier:(double)multipler;
{
	if (self = [super init]) {
		_geometry = [[self class] meshGeometry:multipler];
	}
	return self;
}

+ (SCNGeometry *)meshGeometry:(double) multiplier
{
	// modified from https://github.com/d-ronnqvist/SCNBook-code/tree/master/Chapter%2007%20-%20Custom%20Mesh%20Geometry
	
#define MeshSize 50
	int width  = MeshSize;
	int height = MeshSize;
	
	
	// Generate the index data for the mesh
	// ------------------------------------
	
	NSUInteger surfaceIndexCount = (2 * width + 1) * (height-1);
	// Create a buffer for the index data
	int *surfaceIndices = calloc(surfaceIndexCount, sizeof(int));
	
	// Generate index data as desscribed in the chapter
	int i = 0;
	for (int h=0 ; h<height-1 ; h++) {
		BOOL isEven = h%2 == 0;
		if (isEven) {
			// --->
			for (int w=0 ; w<width ; w++) {
				surfaceIndices[i++] =  h    * width + w;
				surfaceIndices[i++] = (h+1) * width + w;
			}
		} else {
			// <---
			for (int w=width-1 ; w>=0 ; w--) {
				surfaceIndices[i++] = (h+0) * width + w;
				surfaceIndices[i++] = (h+1) * width + w;
			}
		}
		int previous = surfaceIndices[i-1];
		surfaceIndices[i++] = previous;
	}
	NSAssert(surfaceIndexCount == i, @"Should have added as many lines as the size of the buffer");
	
	
	
	// Generate the source data for the mesh
	// -------------------------------------
	
	// Create buffers for the source data
	NSUInteger pointCount = width * height;
	SCNVector3 *vertices = calloc(pointCount, sizeof(SCNVector3));
	SCNVector3 *normals  = calloc(pointCount, sizeof(SCNVector3));
	CGPoint    *UVs = calloc(pointCount, sizeof(CGPoint));
	
	
	// Define the function that is used to calculate the y(x,z)
	GLKVector3(^function)(float, float) = ^(float x, float z) {
		float angle = 1.0/2.0 * sqrt(pow(x, 2) + pow(z, 2));
		return GLKVector3Make(x,
							  multiplier * cos(angle),
							  z);
	};
	
	// Define the range of x and z for which values are calculated
	float minX = -30.0, maxX = 30.0;
	float minZ = -30.0, maxZ = 30.0;
	
	
	for (int h = 0 ; h<height ; h++) {
		for (int w = 0 ; w<width ; w++) {
			// Calculate x and z for this point
			CGFloat x = w/(CGFloat)(width-1)  * (maxX-minX) + minX;
			CGFloat z = h/(CGFloat)(height-1) * (maxZ-minZ) + minZ;
			
			// The index for the vertex/normal/texture buffers
			NSUInteger index = h*width + w;
			
			// Vertex data
			GLKVector3 current = function(x,z);
			vertices[index] = SCNVector3FromGLKVector3(current);
			
			// Normal data
			CGFloat delta = 0.001;
			GLKVector3 nextX   = function(x+delta, z);
			GLKVector3 nextZ   = function(x,       z+delta);
			
			GLKVector3 dx = GLKVector3Subtract(nextX, current);
			GLKVector3 dz = GLKVector3Subtract(nextZ, current);
			
			GLKVector3 normal = GLKVector3Normalize( GLKVector3CrossProduct(dz, dx) );
			normals[index] = SCNVector3FromGLKVector3(normal);
			
			// Texture data
			UVs[index] = CGPointMake(w/(CGFloat)(width-1),
									 h/(CGFloat)(height-1));
		}
	}
	
	
	// Create sources for the vertext/normal/texture data
	SCNGeometrySource *vertexSource  =
	[SCNGeometrySource geometrySourceWithVertices:vertices
											count:pointCount];
	SCNGeometrySource *normalSource  =
	[SCNGeometrySource geometrySourceWithNormals:normals
										   count:pointCount];
	SCNGeometrySource *textureSource =
	[SCNGeometrySource geometrySourceWithTextureCoordinates:UVs
													  count:pointCount];
	
	
	// Create index data ...
	NSData *surfaceIndexData = [NSData dataWithBytes:surfaceIndices
											  length:sizeof(surfaceIndices)*surfaceIndexCount];
	// ... and use it to create the geometry element
	SCNGeometryElement *surfaceElement =
	[SCNGeometryElement geometryElementWithData:surfaceIndexData
								  primitiveType:SCNGeometryPrimitiveTypeTriangleStrip
								 primitiveCount:surfaceIndexCount
								  bytesPerIndex:sizeof(int)];
	SCNGeometryElement *lineElement =
	[SCNGeometryElement geometryElementWithData:surfaceIndexData
								  primitiveType:SCNGeometryPrimitiveTypeLine
								 primitiveCount:surfaceIndexCount
								  bytesPerIndex:sizeof(int)];
	
	// Create the geometry object with the sources and the element
	SCNGeometry *geometry =
	[SCNGeometry geometryWithSources:@[vertexSource, normalSource, textureSource]
							elements:@[surfaceElement]];
	// Give it a blue checker board texture
	SCNMaterial *blueCheckerboardMaterial      = [SCNMaterial material];
	blueCheckerboardMaterial.diffuse.contents  = [NSImage imageNamed:@"checkerboard"];
	blueCheckerboardMaterial.specular.contents = [NSColor darkGrayColor];
	blueCheckerboardMaterial.shininess         = 0.25;
	
	// Scale down the image when used as a texture ...
	blueCheckerboardMaterial.diffuse.contentsTransform = CATransform3DMakeScale(20.0, 20.0, 1.0);
	// ... and make it repeat
	blueCheckerboardMaterial.diffuse.wrapS = SCNRepeat;
	blueCheckerboardMaterial.diffuse.wrapT = SCNRepeat;
	
	SCNMaterial *yellowMaterial             = [SCNMaterial material];
	yellowMaterial.ambient.contents         = [NSColor yellowColor];
	yellowMaterial.cullMode = SCNCullFront;
	yellowMaterial.doubleSided = NO;
	
	SCNMaterial *lineMaterial      = [SCNMaterial material];
	lineMaterial.emission.contents = [NSColor whiteColor];
	
	geometry.materials = @[blueCheckerboardMaterial];
//	geometry.materials = @[lineMaterial];
	NSLog(@"geometry element count %zd", geometry.geometryElementCount);
	return geometry;
}

@end
