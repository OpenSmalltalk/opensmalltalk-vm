
//  nsPoolManagement.h
//  CoreVM
//
//  Created by Brad Fowlow on 10/15/09.
//  Copyright (c) 2013 3D Immersive Collaboration Consulting, LLC.

// Main autorelese-pool drain/reset.
// To be called regularly,
// *between* interpretation steps that might involve prim or FFI calls.

void sqCycleMainAutoreleasePool (void);

