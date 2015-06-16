//
//  ViewController.m
//  Mesh Demo
//
//  Created by Hal Mueller on 5/19/15.
//  Copyright (c) 2015 UW GeoClaw. All rights reserved.
//

#import "ViewController.h"
#import "MVKMesh.h"

@import GLKit;

@interface ViewController ()
@property (nonatomic, strong) IBOutlet SCNView *sceneView;
@property (nonatomic, strong) MVKMesh *mesh;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	SCNScene *scene = [[SCNScene alloc] init];
	self.sceneView.scene = scene;
	self.sceneView.backgroundColor = [NSColor lightGrayColor];
	self.sceneView.showsStatistics = YES;
	[self addGeoclawFile:[NSURL fileURLWithPath:@"/Users/hal/Downloads/viewpandem.txt"]];
	
	[scene.rootNode addChildNode:[[self class] ambientLights]];
//	[scene.rootNode addChildNode:[[self class] floorNode]];

/*	let scene = SCNScene()
	let sceneView = SCNView()
	sceneView.frame = self.view.frame
	sceneView.autoresizingMask = UIViewAutoresizing.allZeros
	sceneView.scene = scene
	sceneView.autoenablesDefaultLighting = true
	sceneView.allowsCameraControl = true
	sceneView.backgroundColor = UIColor.blueColor()
	self.view = sceneView
	
	//Add camera to scene.
	let camera = self.makeCamera()
	scene.rootNode.addChildNode(camera)
	
	//Add some ambient light so it's not so dark.
	let lights = self.makeAmbientLight()
	scene.rootNode.addChildNode(lights)
	
	//Create and add the floor.
	let floor = self.makeFloor()
	scene.rootNode.addChildNode(floor)
*/
	
}

// Seashell code from http://www.mattrajca.com/2014/05/14/modeling-parametric-surfaces-with-scenekit.html

typedef struct {
	float x, y, z;
	float nx, ny, nz;
} Vertex;

#define SUBDIVISIONS 250

- (SCNGeometry *)newSeashell {
	// Allocate enough space for our vertices
	NSInteger vertexCount = (SUBDIVISIONS + 1) * (SUBDIVISIONS + 1);
	Vertex *vertices = malloc(sizeof(Vertex) * vertexCount);
	unsigned short *indices = malloc(sizeof(unsigned short) * vertexCount * 6);
	
	// Calculate the uv step interval given the number of subdivisions
	float uStep = 2.0f * M_PI / SUBDIVISIONS; // (2pi - 0) / subdivisions
	float vStep = 4.0f * M_PI / SUBDIVISIONS; // (2pi - -2pi) / subdivisions
	
	Vertex *curr = vertices;
	float u = 0.0f;
	
	// Loop through our uv-space, generating 3D vertices
	for (NSInteger i = 0; i <= SUBDIVISIONS; ++i, u += uStep) {
		float v = -2 * M_PI;
		
		for (NSInteger j = 0; j <= SUBDIVISIONS; ++j, v += vStep, ++curr) {
			curr->x = 5/4.0f * (1-v/(2*M_PI)) * cos(2*v) * (1 + cos(u)) + cos(2*v);
			curr->y = 5/4.0f * (1-v/(2*M_PI)) * sin(2*v) * (1 + cos(u)) + sin(2*v);
			curr->z = 5*v / M_PI + 5/4.0f * (1 - v/(2*M_PI)) * sin(u) + 15;
			
			// STEP 2: add normal equations here
			curr->nx = (-5*(2*M_PI - v)*(2*(20 + 18*M_PI - 5*v)*cos(u - 2*v) + 5*(2*M_PI - v)*cos(2*(u - v)) + 20*M_PI*cos(2*v) - 10*v*cos(2*v) + 10*M_PI*cos(2*(u + v)) - 5*v*cos(2*(u + v)) - 40*cos(u + 2*v) + 36*M_PI*cos(u + 2*v) - 10*v*cos(u + 2*v) + 5*sin(u - 2*v) - 10*sin(2*v) - 5*sin(u + 2*v)))/(128.*pow(M_PI,2));
			
			curr->ny = (-5*(2*M_PI - v)*(5*pow(cos(v),2)*(1 + cos(u) - 8*sin(u)) - 5*sin(v)*(4*v*pow(cos(u),2)*cos(v) + (1 + cos(u) - 8*sin(u))*sin(v)) + 2*cos(u)*(18*M_PI - 5*v + 10*M_PI*cos(u))*sin(2*v)))/(64.*pow(M_PI,2));
			
			curr->nz = (-5*(2*M_PI - v)*(18*M_PI - 5*v + 5*(2*M_PI - v)*cos(u))*sin(u))/(32.*pow(M_PI,2));
			
			// Normalize the results
			float invLen = 1.0f / sqrtf(curr->nx * curr->nx + curr->ny * curr->ny + curr->nz * curr->nz);
			curr->nx *= invLen;
			curr->ny *= invLen;
			curr->nz *= invLen;
		}
	}
	
	// STEP 3: generate indices
	// Generate indices
	unsigned short *idx = indices;
	unsigned short stripStart = 0;
	unsigned short indexCount = 0;
	
	for (NSInteger i = 0; i < SUBDIVISIONS; ++i, stripStart += (SUBDIVISIONS + 1)) {
		for (NSInteger j = 0; j < SUBDIVISIONS; ++j) {
			indexCount++;
			
			unsigned short v1 = stripStart + j;
			unsigned short v2 = stripStart + j + 1;
			unsigned short v3 = stripStart + (SUBDIVISIONS+1) + j;
			unsigned short v4 = stripStart + (SUBDIVISIONS+1) + j + 1;
			
			*idx++ = v4;
			*idx++ = v2;
			*idx++ = v3;
			*idx++ = v1;
			*idx++ = v3;
			*idx++ = v2;
		}
	}
	// STEP 4: return geometry
	NSData *data = [NSData dataWithBytes:vertices length:vertexCount * sizeof(Vertex)];
	free(vertices);
	NSLog(@"indexCount %zd", indexCount);
	NSLog(@"vertexCount %zd", vertexCount);
	SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithData:data
																 semantic:SCNGeometrySourceSemanticVertex
															  vectorCount:vertexCount
														  floatComponents:YES
													  componentsPerVector:3
														bytesPerComponent:sizeof(float)
															   dataOffset:0
															   dataStride:sizeof(Vertex)];
	
	SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithData:data
																	   semantic:SCNGeometrySourceSemanticNormal
																	vectorCount:vertexCount
																floatComponents:YES
															componentsPerVector:3
															  bytesPerComponent:sizeof(float)
																	 dataOffset:offsetof(Vertex, nx)
																	 dataStride:sizeof(Vertex)];
	
	SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:indices length:indexCount * sizeof(unsigned short)]
																primitiveType:SCNGeometryPrimitiveTypeLine
//																primitiveType:SCNGeometryPrimitiveTypeTriangles
															   primitiveCount:indexCount/3
																bytesPerIndex:sizeof(unsigned short)];
	
	free(indices);
	
	return [SCNGeometry geometryWithSources:@[source, normalSource] elements:@[element]];
}

- (void)addMesh
{
	self.mesh = [MVKMesh cosineWaveMesh];
	SCNNode *meshNode = [SCNNode node];
	[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.lineGeometry]];
	[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.topSurfaceGeometry]];
	[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.bottomSurfaceGeometry]];
	
	[self.sceneView.scene.rootNode addChildNode:meshNode];
}

- (void)addGeoclawFile:(NSURL *)geoclawURL
{
	NSError *error;
	self.mesh = [MVKMesh meshFromGeoClawExport:geoclawURL encoding:NSUTF8StringEncoding error:&error];
	if (self.mesh) {
		SCNNode *meshNode = [SCNNode node];
		[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.lineGeometry]];
		[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.topSurfaceGeometry]];
		[meshNode addChildNode:[SCNNode nodeWithGeometry:self.mesh.bottomSurfaceGeometry]];
		
		[self.sceneView.scene.rootNode addChildNode:meshNode];
	}
	else {
		NSLog(@"error adding Geoclaw file %@ %@", geoclawURL, error.localizedFailureReason);
	}
}

- (void)addSeashell:(SCNScene *)scene;
{
	SCNGeometry *seashell = [self newSeashell];
//	seashell.materials
	[scene.rootNode addChildNode:[SCNNode nodeWithGeometry:seashell]];
}

- (void)addCylinder:(SCNScene *)scene;
{
	SCNCylinder *cylGeom = [SCNCylinder cylinderWithRadius:0.5 height:1.0];
	SCNNode *cylNode = [SCNNode nodeWithGeometry:cylGeom];
	cylNode.position = SCNVector3Make(2., 2., 8.0);
	[scene.rootNode addChildNode:cylNode];
}
+ (SCNNode *)ambientLights
{
	SCNNode *lightNode = [SCNNode new];
	SCNLight *light = [SCNLight light];
	light.type = SCNLightTypeAmbient;
	light.color = [NSColor colorWithWhite:0.1 alpha:1.0];
	lightNode.light = light;
	return lightNode;
}

+ (SCNNode *)floorNode
{
	SCNNode *floorNode = [[SCNNode alloc] init];
	SCNFloor *floor = [[SCNFloor alloc] init];
	floor.reflectivity = .5;
	floorNode.geometry = floor;
	SCNMaterial *floorMaterial = [SCNMaterial new];
	floorMaterial.litPerPixel = NO;
	floorMaterial.diffuse.contents = [NSColor blackColor];
//	floorMaterial.diffuse.contents = [NSImage imageNamed:@"green2.png"];
//	floorMaterial.diffuse.wrapS = SCNWrapModeRepeat;
//	floorMaterial.diffuse.wrapT = SCNWrapModeRepeat;
	floor.materials = @[floorMaterial];
	return floorNode;
}

/*
 func makeFloor() -> SCNNode {
 let floor = SCNFloor()
 floor.reflectivity = 0
 let floorNode = SCNNode()
 floorNode.geometry = floor
 let floorMaterial = SCNMaterial()
 floorMaterial.litPerPixel = false
 floorMaterial.diffuse.contents = UIImage(named:"green2.png")
 floorMaterial.diffuse.wrapS = SCNWrapMode.Repeat
 floorMaterial.diffuse.wrapT = SCNWrapMode.Repeat
 floor.materials = [floorMaterial]
 return floorNode
 }

 */
- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

@end
