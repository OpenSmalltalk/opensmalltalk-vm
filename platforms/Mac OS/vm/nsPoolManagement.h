
//  nsPoolManagement.h
//  CoreVM
//
//  Created by Brad Fowlow on 10/15/09.
//  Copyright 2009 Teleplace, Inc. All rights reserved.

// Main autorelese-pool drain/reset.
// To be called regularly,
// *between* interpretation steps that might involve prim or FFI calls.

void sqCycleMainAutoreleasePool (void);

