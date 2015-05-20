//
//  ViewController.m
//  Mesh Demo
//
//  Created by Hal Mueller on 5/19/15.
//  Copyright (c) 2015 UW GeoClaw. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, retain) IBOutlet SCNView *sceneView;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	SCNScene *scene = [[SCNScene alloc] init];
	self.sceneView.scene = scene;
	self.sceneView.backgroundColor = [NSColor blueColor];
	SCNNode *rootNode = [SCNNode node];
	SCNCylinder *cylGeom = [SCNCylinder cylinderWithRadius:0.5 height:1.0];
	SCNNode *cylNode = [SCNNode nodeWithGeometry:cylGeom];
	cylNode.position = SCNVector3Make(2., 2., 8.0);
	[scene.rootNode addChildNode:cylNode];
	
	[scene.rootNode addChildNode:[[self class] ambientLights]];
	[scene.rootNode addChildNode:[[self class] floorNode]];

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
	floorMaterial.diffuse.contents = [NSImage imageNamed:@"green2.png"];
	floorMaterial.diffuse.wrapS = SCNWrapModeRepeat;
	floorMaterial.diffuse.wrapT = SCNWrapModeRepeat;
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
