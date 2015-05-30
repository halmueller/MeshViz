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
@property (nonatomic, strong) SCNGeometry *topSurfaceGeometry;
@property (nonatomic, strong) SCNGeometry *bottomSurfaceGeometry;
@property (nonatomic, strong) SCNGeometry *lineGeometry;
@end

@implementation MVKMesh

+ (instancetype)cosineWaveMesh;
{
	MVKMesh *result = [MVKMesh new];
	
	// modified from https://github.com/d-ronnqvist/SCNBook-code/tree/master/Chapter%2007%20-%20Custom%20Mesh%20Geometry
	
#define MeshSize 1024
	int width  = MeshSize;
	int height = MeshSize;
	
	
	// Generate the index data for the mesh surface
	// --------------------------------------------
	
	NSUInteger surfaceIndexCount = (2 * width + 1) * (height-1);
	// Create a buffer for the index data
	int *surfaceIndices = calloc(surfaceIndexCount, sizeof(int));
	
	// Generate surface index data as desscribed in the chapter
	int surfaceIndicesIndex = 0;
	for (int h=0 ; h<height-1 ; h++) {
		BOOL isEven = h%2 == 0;
		if (isEven) {
			// --->
			for (int w=0 ; w<width ; w++) {
				surfaceIndices[surfaceIndicesIndex++] =  h    * width + w;
				surfaceIndices[surfaceIndicesIndex++] = (h+1) * width + w;
			}
		} else {
			// <---
			for (int w=width-1 ; w>=0 ; w--) {
				surfaceIndices[surfaceIndicesIndex++] = (h+0) * width + w;
				surfaceIndices[surfaceIndicesIndex++] = (h+1) * width + w;
			}
		}
		int previous = surfaceIndices[surfaceIndicesIndex-1];
		surfaceIndices[surfaceIndicesIndex++] = previous;
	}
	NSAssert(surfaceIndexCount == surfaceIndicesIndex, @"Should have added as many lines as the size of the buffer");
	

	// generate wireframe line index data
	NSUInteger gridIndexCount = ((width * height * 2) + width + height) * 2;
	int *gridIndices = calloc(gridIndexCount, sizeof(int));
	
	int gridIndicesIndex = 0;
	for (int h = 0; h < height-1; h++ ) {
		for (int w = 0; w < width-1; w++) {
			int start = h*(width ) + w;
			int finish = start + 1;
			gridIndices[gridIndicesIndex++] = start;
			gridIndices[gridIndicesIndex++] = finish;
		}
		if (h < height-2) {
			for (int w = 0; w < width-1; w++) {
				int start = h*(width ) + w;
				int finish = start + width;
				gridIndices[gridIndicesIndex++] = start;
				gridIndices[gridIndicesIndex++] = finish;
			}
		}
	}
	NSAssert(gridIndexCount >= gridIndicesIndex, @"%zd %zd: added more endpoint pairs than buffer size allocated", gridIndexCount, gridIndicesIndex);
	
	
	// Generate the source data for the mesh
	// -------------------------------------
	
	// Create buffers for the source data
	NSUInteger pointCount = width * height;
	SCNVector3 *vertices = calloc(pointCount, sizeof(SCNVector3));
	SCNVector3 *normals  = calloc(pointCount, sizeof(SCNVector3));
	SCNVector3 *reverseNormals  = calloc(pointCount, sizeof(SCNVector3));
	CGPoint    *UVs = calloc(pointCount, sizeof(CGPoint));
	
	
	// Define the function that is used to calculate the y(x,z)
	GLKVector3(^function)(float, float) = ^(float x, float z) {
		float angle = 1.0/2.0 * sqrt(pow(x, 2) + pow(z, 2));
		return GLKVector3Make(x,
							  6 + 3. * cos(angle),
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
			GLKVector3 reverseNormal = GLKVector3Negate(normal);
			reverseNormals[index] = SCNVector3FromGLKVector3(reverseNormal);
			
			// Texture data
			UVs[index] = CGPointMake(w/(CGFloat)(width-1),
									 h/(CGFloat)(height-1));
		}
	}
	
	
	// Create sources for the vertex/normal/texture data
	SCNGeometrySource *vertexSource  = [SCNGeometrySource geometrySourceWithVertices:vertices
																			   count:pointCount];
	free(vertices);
	SCNGeometrySource *normalSource  = [SCNGeometrySource geometrySourceWithNormals:normals
																			  count:pointCount];
	free(normals);
	SCNGeometrySource *reverseNormalSource  = [SCNGeometrySource geometrySourceWithNormals:reverseNormals
																					 count:pointCount];
	free(reverseNormals);
	SCNGeometrySource *textureSource = [SCNGeometrySource geometrySourceWithTextureCoordinates:UVs
																						 count:pointCount];
	free(UVs);
	
	
	// Create index data ...
	NSData *surfaceIndexData = [NSData dataWithBytes:surfaceIndices
											  length:sizeof(surfaceIndices)*surfaceIndexCount];
	free(surfaceIndices);
	// ... and use it to create the geometry element
	SCNGeometryElement *topSurfaceElement = [SCNGeometryElement geometryElementWithData:surfaceIndexData
																	   primitiveType:SCNGeometryPrimitiveTypeTriangleStrip
																	  primitiveCount:surfaceIndexCount
																	   bytesPerIndex:sizeof(int)];
	
	
	NSData *lineIndexData = [NSData dataWithBytes:gridIndices length:sizeof(surfaceIndices)*gridIndexCount];
	SCNGeometryElement *lineElement = [SCNGeometryElement geometryElementWithData:lineIndexData
																	primitiveType:SCNGeometryPrimitiveTypeLine
																   primitiveCount:gridIndexCount
																	bytesPerIndex:sizeof(int)];
	
	// Create the geometry object with the sources and the element
	result.topSurfaceGeometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource, textureSource]
														elements:@[topSurfaceElement]];
	result.bottomSurfaceGeometry = [SCNGeometry geometryWithSources:@[vertexSource, reverseNormalSource, textureSource]
														   elements:@[topSurfaceElement]];
	
	
	
	result.lineGeometry = [SCNGeometry geometryWithSources:@[vertexSource] elements:@[lineElement]];
	
	[result addDefaultMaterials];
	
	return result;
}

- (void)addDefaultMaterials;
{
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
	self.topSurfaceGeometry.materials = @[blueCheckerboardMaterial];
	
	SCNMaterial *yellowMaterial             = [SCNMaterial material];
	yellowMaterial.diffuse.contents         = [NSColor yellowColor];
	yellowMaterial.cullMode = SCNCullFront;
	//	yellowMaterial.doubleSided = YES;
	self.bottomSurfaceGeometry.materials = @[yellowMaterial];
	
	SCNMaterial *lineMaterial      = [SCNMaterial material];
	lineMaterial.emission.contents = [NSColor greenColor];
	lineMaterial.emission.contents = [NSColor blackColor];
	self.lineGeometry.materials = @[lineMaterial];

}

@end
