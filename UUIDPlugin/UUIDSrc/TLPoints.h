/*------------------------------------------------------------
| TLPoints.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to data point functions.
|
| DESCRIPTION:
|        
| NOTE: 
|
| HISTORY: 02.25.00 From 'TLPointList.h'.
|          02.25.00 Moved 'XY' and 'RA' here from 'TLTypes.h'.
------------------------------------------------------------*/

#ifndef TLPOINTS_H
#define TLPOINTS_H

#ifdef __cplusplus
extern "C"
{
#endif

// Type definitions and forward references to the structures 
// defined below.
typedef struct PointGroup   PointGroup;

// A 2D point in the Cartesian coordinate system.
typedef struct
{
    f64 x; 
    f64 y; 
} XY;

// A 2D point in the polar coordinate system.
typedef struct
{
    f64 r; // The radius vector.
    f64 a; // The vectorial angle.
} RA;


/*------------------------------------------------------------
| PointGroup
|-------------------------------------------------------------
|
| PURPOSE: To provide a storage area for a limited number of
|          fixed size data points.
|
| DESCRIPTION: A point group can have less actual points than
| the upper limit defined for the group but it can't extend 
| that limit.  
|
| Once the group membership limit has been reached subsequent 
| additions to the group replace other points in the group in 
| chronological order in which the points were added to the 
| group.
|
| This permits the 'PointGroup' structure to be used as a
| ring buffer for data points which is useful for time series
| data.
| 
| NOTE:  
|
| HISTORY: 02.25.00 From 'RecordBlock'.
------------------------------------------------------------*/
struct PointGroup
{
    u32             PointCount; 
                        // Number of points currently in the 
                        // group.
                        //
    u32             MaxPointCount;  
                        // Maximum number of points that can
                        // be in the group.
                        //
    u32             BytesPerPoint;
                        // How many bytes are occupied by
                        // each data point.
                        //
    f64*            FirstPoint;    
                        // Where the data records are stored, 
                        // the address of the first data 
                        // record in the block if there is one.
                        //
    f64*            EndOfData;   
                        // Where the actual data records end, 
                        // the first byte after the last 
                        // actual data record.
                        //
    f64*            EndOfBlock;     
                        // The first byte after the buffer
                        // where the points are stored,
                        // the physical limit to adding
                        // points.
};


#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLPOINTS_H
