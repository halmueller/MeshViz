//
//  MVKMesh.h
//  Mesh Demo
//
//  Created by Hal Mueller on 5/26/15.
//  Copyright (c) 2015 UW GeoClaw. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface MVKMesh : SCNGeometry
@property (nonatomic, readonly) SCNGeometry *topSurfaceGeometry;
@property (nonatomic, readonly) SCNGeometry *bottomSurfaceGeometry;
@property (nonatomic, readonly) SCNGeometry *lineGeometry;
@property (nonatomic, readonly) double eastEdgeMeters;
@property (nonatomic, readonly) double westEdgeMeters;
@property (nonatomic, readonly) double northEdgeMeters;
@property (nonatomic, readonly) double southEdgeMeters;

+ (instancetype)cosineWaveMesh;
+ (instancetype)meshFromGeoClawExport:(NSURL *)exportedFile encoding:(NSStringEncoding)encoding error:(NSError **)error;

@end
