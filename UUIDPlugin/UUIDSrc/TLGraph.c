/*------------------------------------------------------------
| TLGraph.c
|-------------------------------------------------------------
|
| PURPOSE: To provide graphics functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 02.27.96 from 'SillyBalls.c' by way of
|                   'Permutation.c'.
------------------------------------------------------------*/
    
#include "TLTarget.h" // Include this first.

#include <stdarg.h>
#include <Types.h>
#include <Memory.h>
#include <Quickdraw.h>
#include <Fonts.h>
#include <Events.h>
#include <Menus.h>
#include <Windows.h>
#include <TextEdit.h>
#include <Dialogs.h>
#include <OSUtils.h>
#include <ToolUtils.h>
#include <TextUtils.h>
#include <SegLoad.h>
#include <Sound.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "TLTypes.h"
#include "TLBit.h"
#include "TLBytes.h"
#include "TLAscii.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLSubRandom.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLList.h"
#include "TLMatrixAlloc.h"
#include "TLMatrixExtra.h"
#include "TLArray.h"
#include "TLPoints.h"
#include "TLGeometry.h"
#include "TLWeight.h"
#include "TLStat.h"
#include "TLGraph.h"

// Globals:

// Fonts
GraphFont Monaco9 =
{
    (s8*) "Monaco9",
#if ( __MWERKS__ >= 0x2000 ) // Release 2+
    kFontIDMonaco,
#else
    monaco,
#endif
    6,
    9
};

// Colors:
RGBColor    Black;
RGBColor    Yellow;
RGBColor    Magenta;
RGBColor    Red;
RGBColor    Orange;
RGBColor    Cyan;
RGBColor    Green;
RGBColor    Blue;
RGBColor    White;

// The current graphics window.
WindowPtr   TheGraphicsWindow;

// The rectangle of the current graphics window.
Rect        TheGraphicsWindowRect;

// The current number of pixels to use for representing
// a cell of a matrix.
s32         XPixelsPerMatrixCell;
s32         YPixelsPerMatrixCell;

// The current graph font parameters.
s32     CurrentGraphFont;   // ID number of of the current 
                                // graph font, eg. 'monaco'. 
                                //
s32     CurrentGraphFontHeight; // The height in points (1/72nd") 
                                // of the current graph font.
                                //
s32     CurrentGraphFontWidth;  // The width in points (1/72nd") 
                                // of the current graph font.
                                //

// The rectangle used by default for plotting graphs.
Rect    DefaultGraphRect = { 20, 20, 500, 500 };

/*------------------------------------------------------------
| AddLabelToGraph
|-------------------------------------------------------------
|
| PURPOSE: To add a text label to a graph.
|
| DESCRIPTION: Adds a label to the graph.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.01.97 
------------------------------------------------------------*/
void
AddLabelToGraph( LineGraph* AGraph, TextLabel* T )
{
    // Link the label to the graph.
    T->Graph = AGraph;
    
    // Link the graph to the text label.
    InsertDataLastInList( AGraph->Labels, (u8*) T );
}

/*------------------------------------------------------------
| AlignRectToRect
|-------------------------------------------------------------
|
| PURPOSE: To align a movable rectangle relative to a fixed
|          rectangle.
|
| DESCRIPTION: 
|
| Alignment constants for rectangles: where the movable 
| rectangle is placed relative to the fixed alignment 
| rectangle.
|                   Fixed Alignment Rectangle
|  ----------------------------------------------------------
|  | AlignTopLeft        AlignTopCenter      AlignTopRight  |
|  |                                                        |
|  |                                                        |
|  | AlignCenterLeft    AlignCenterCenter  AlignCenterRight |
|  |                                                        |
|  |                                                        |
|  | AlignBottomLeft    AlignBottomCenter  AlignBottomRight |
|  ----------------------------------------------------------
|
| EXAMPLE:  
|
| NOTE: See 'TLGraph.h' for details of alignment code encoding.
|
| ASSUMES: 
|           
| HISTORY: 02.01.97 from 'DrawDataSeries'. 
------------------------------------------------------------*/
void
AlignRectToRect( Rect* Movable, 
                 Rect* Fixed,
                 s32   AlignmentCode )
{
    s32 MidX, MidXLeft;
    s32 MidY, MidYTop;
    s32 MovableHeight, MovableWidth;
    
    MovableHeight = Movable->bottom - Movable->top;
    MovableWidth  = Movable->right  - Movable->left;
    
    if( AlignmentCode & AlignLeft )
    {
        Movable->left  = Fixed->left;
        Movable->right = Fixed->left + MovableWidth;
    }
            
    if( AlignmentCode & AlignRight )
    {
        Movable->left  = Fixed->right - MovableWidth;
                    
        Movable->right = Fixed->right;
    }
        
    if( AlignmentCode & AlignTop )
    {
        Movable->top    = Fixed->top;
        Movable->bottom = Fixed->top + MovableHeight;
    }
    
    if( AlignmentCode & AlignBottom )
    {
        Movable->top    = Fixed->bottom - MovableHeight;
                    
        Movable->bottom = Fixed->bottom;
    }
        
    if( AlignmentCode & AlignCenterX )
    {
        MidX = ( Fixed->right + Fixed->left ) / 2;
                         
        MidXLeft = MidX - ( MovableWidth / 2 );
                       
        Movable->left  = MidXLeft;
        Movable->right = MidXLeft + MovableWidth;
    }
    
    if( AlignmentCode & AlignCenterY )
    {
        MidY = ( Fixed->top + Fixed->bottom ) / 2;
                         
        MidYTop = MidY - ( MovableHeight / 2 );
                       
        Movable->top    = MidYTop;
        Movable->bottom = MidYTop + MovableHeight;
    }
}

/*------------------------------------------------------------
| AddLinesToGraph
|-------------------------------------------------------------
|
| PURPOSE: To add a vector of connected (x,y) points to graph.
|
| DESCRIPTION: Adds a vector to be plotted as connected 
| points in the given color.
|
| Automatically rescales the line graph to include all points.
|
| Returns a reference to the data series so that further
| adjustments can be made.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.01.96 
------------------------------------------------------------*/
DataSeries*
AddLinesToGraph( LineGraph* AGraph, Vector* V, RGBColor* AColor )
{
    DataSeries* ASeries;
    
    ASeries = MakeDataSeries( AGraph, 0, V, AColor );

    // Adjust the data space window to include the points.
    AutoScaleLineGraph( AGraph );
    
    return( ASeries );
}

/*------------------------------------------------------------
| AddPointsToGraph
|-------------------------------------------------------------
|
| PURPOSE: To add a vector of (x,y) points to graph.
|
| DESCRIPTION: Adds a vector to be plotted as un-connected 
| points in the given color.
|
| Automatically rescales the line graph to include all points.
|
| Returns a reference to the data series so that further
| adjustments can be made.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.01.96 
------------------------------------------------------------*/
DataSeries*
AddPointsToGraph( LineGraph* AGraph, Vector* V, RGBColor* AColor )
{
    DataSeries* ASeries;
    
    ASeries = MakeDataSeries( AGraph, 0, V, AColor );

    ASeries->IsConnected = 0;
    ASeries->IsPointsDrawn = 1;
    ASeries->PointRadius = 1.0;
    
    // Adjust the data space window to include the points.
    AutoScaleLineGraph( AGraph );
    
    return( ASeries );
}

/*------------------------------------------------------------
| AutoScaleLineGraph
|-------------------------------------------------------------
|
| PURPOSE: To automatically set the scale of a line graph so
|          that all data series points are visible.
|
| DESCRIPTION: Makes 10% a border around the points.  Scales
| X and Y independently.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.01.96 
|          05.22.96 added 'IsDataSpaceBorder'.
------------------------------------------------------------*/
void
AutoScaleLineGraph( LineGraph* AGraph )
{
    f64     LoX, LoY, HiX, HiY;
    f64     lox, loy, hix, hiy;
    f64     XBorder, YBorder;
    u32         IsEmpty;
    DataSeries* ADataSeries;
    
    IsEmpty = 1;
    
    // For each data series find the range of the values.
    ReferToList( AGraph->Data ); 
    
    while( TheItem )
    {
        ADataSeries = (DataSeries*) TheDataAddress;
        
        ExtentOfVector( ADataSeries->Data, 
                        &lox, &hix, &loy, &hiy );
        
        // Set the initial values.
        if( IsEmpty ) 
        {
            IsEmpty = 0;
            
            LoX = lox;
            LoY = loy;
            HiX = hix;
            HiY = hiy;
        }
        else // Update extremes.
        {
            if( lox < LoX ) LoX = lox;
            if( hix > HiX ) HiX = hix;
            if( loy < LoY ) LoY = loy;
            if( hiy > HiY ) HiY = hiy;
        }
        
        // Advance to next data series. 
        ToNextItem();
    }
    
    RevertToList();
    
    // Compute the borders.
    if( AGraph->IsDataSpaceBorder )
    {
        XBorder = (HiX - LoX)/20.0;
        YBorder = (HiY - LoY)/20.0;
    }
    else
    {
        XBorder = 0;
        YBorder = 0;
    }
    
    // Set the extent of the graph in data space to include
    // the borders and all data points.
    AGraph->XMin = LoX - XBorder;
    AGraph->XMax = HiX + XBorder;
    AGraph->YMin = LoY - YBorder;
    AGraph->YMax = HiY + YBorder;
}

/*------------------------------------------------------------
| AutoScaleLineGraphSquare
|-------------------------------------------------------------
|
| PURPOSE: To automatically set the scale of a line graph so
|          that all data series points are visible.
|
| DESCRIPTION: Makes 10% a border around the points.  Scales
| X and Y to the same unit.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.03.96 
|          05.22.96 added 'IsDataSpaceBorder'.
------------------------------------------------------------*/
void
AutoScaleLineGraphSquare( LineGraph* AGraph )
{
    f64     LoX, LoY, HiX, HiY;
    f64     lox, loy, hix, hiy;
    f64     XBorder, YBorder, Border, Extent;
    u32         IsEmpty;
    DataSeries* ADataSeries;
    
    IsEmpty = 1;
    
    // For each data series find the range of the values.
    ReferToList( AGraph->Data ); 
    
    while( TheItem )
    {
        ADataSeries = (DataSeries*) TheDataAddress;
        
        ExtentOfVector( ADataSeries->Data, 
                        &lox, &hix, &loy, &hiy );
        
        // Set the initial values.
        if( IsEmpty ) 
        {
            IsEmpty = 0;
            
            LoX = lox;
            LoY = loy;
            HiX = hix;
            HiY = hiy;
        }
        else // Update extremes.
        {
            if( lox < LoX ) LoX = lox;
            if( hix > HiX ) HiX = hix;
            if( loy < LoY ) LoY = loy;
            if( hiy > HiY ) HiY = hiy;
        }
        
        // Advance to next data series. 
        ToNextItem();
    }
    
    RevertToList();
    
    // Compute the borders.
    if( AGraph->IsDataSpaceBorder )
    {
        XBorder = (HiX - LoX)/20.0;
        YBorder = (HiY - LoY)/20.0;
    }
    else
    {
        XBorder = 0;
        YBorder = 0;
    }
    
    Border = max( XBorder, YBorder );
    Extent = max( HiX - LoX, HiY - LoY );
    
    // Set the extent of the graph in data space to include
    // the borders and all data points.
    AGraph->XMin = LoX - Border;
    AGraph->YMin = LoY - Border;
    
    AGraph->XMax = LoX + Extent;
    AGraph->YMax = LoY + Extent;
}

/*------------------------------------------------------------
| CalculateTextExtent
|-------------------------------------------------------------
|
| PURPOSE: To calculate the rectangle that bounds the string
|          at the given upper-left point.
|
| DESCRIPTION: Return the extent rectangle relative to a
| point in an image space with point-size units.
|
|             Origin pixel: defines placement
|            /
|     --- --/----------  ---
|      |  |+...@......|   |
|      H  |...@.@.....|   |
|      e  |..@...@....|  TopToBaseline
|      i  |.@@@@@@@...|   |
|      g  |@.......@..|   |
|      h --...........---------- Baseline
|      t  |..........*|<-- Last pixel: defines extent
|     --- ------------- 
|         |<--Width-->| \_ TextExtent rectangle
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: The current font size is valid.
|          Font is mono-spaced, that is, non-proportional 
|          spacing.
|           
| HISTORY: 02.01.97 from 'TextRect'.
------------------------------------------------------------*/
Rect*
CalculateTextExtent( s32 x, s32 y, GraphFont* F, s8* Text )
{
    static Rect ARect;
    
    s16 w;
    
    // Calculate how many pixels wide the text is.
    w = CountString( Text ) * F->FontWidth;
    
    // Calculate the bounding rectangle.
    
    // Set the origin pixel.
    ARect.top    = y;
    ARect.left   = x;
    
    // Set the last pixel.
    ARect.bottom = y + F->FontHeight;
    ARect.right  = x + w;
    
    return( &ARect );
}
            
/*------------------------------------------------------------
| ClearGraphicsWindow
|-------------------------------------------------------------
|
| PURPOSE: To fill the graphics window with white.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.27.96 
|
------------------------------------------------------------*/
void
ClearGraphicsWindow()
{
    DrawFilledRectangle( &TheGraphicsWindowRect, &White );
}

/*------------------------------------------------------------
| ClearTextLine
|-------------------------------------------------------------
|
| PURPOSE: To clear a line that could hold text starting at
|          a certain point and continuing to the right hand
|          border.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.27.96 
|
------------------------------------------------------------*/
void
ClearTextLine( s32 x, s32 y )
{
    Rect    ARect;
    
    ARect.top = y;
    ARect.left = x;
    ARect.right = TheGraphicsWindowRect.right;
    ARect.bottom = y + 2 + CurrentGraphFontHeight;
    
    DrawFilledRectangle( &ARect, &White );
}

/*------------------------------------------------------------
| CloseTextEditWindow
|-------------------------------------------------------------
|
| PURPOSE: To clean up a graphics  window created using
|          'OpenGraphicsWindow'.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.26.96 
|
------------------------------------------------------------*/
void            
CloseGraphicsWindow( WindowPtr AWindow )
{
    DisposeWindow( AWindow );
} 

/*------------------------------------------------------------
| DeleteGraph
|-------------------------------------------------------------
|
| PURPOSE: To delete the storage of a line graph and associated
|          data series records.
|
| DESCRIPTION: Doesn't alter the image of the line graph on
|              the screen.
|
| Doesn't alter the data vector. 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.28.96 
|          01.29.97 added deletion of label list.
|          02.01.97 revised deletion of label list.
------------------------------------------------------------*/
void
DeleteGraph( LineGraph* AGraph )
{
    DataSeries* ASeries;
    TextLabel*  T;
        
    // Delete the window point buffer of each data series.
    ReferToList( AGraph->Data ); 

    while( TheItem )
    {
        // Refer to the series.
        ASeries = (DataSeries*) TheDataAddress;
        
        // Free the window coordinate data.
        free( ASeries->WinPt );
        
        // Free the data series record itself.
        free( ASeries );
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Delete the list and items.
    DeleteList( AGraph->Data );
    
    // Delete the text labels if any.
    if( AGraph->Labels->ItemCount )
    {
        // Delete the string buffer of each text label
        ReferToList( AGraph->Labels ); 

        while( TheItem )
        {
            // Refer to the series.
            T = (TextLabel*) TheDataAddress;
        
            // Free the string buffer.
            free( T->Text );
        
            // Free the text label record itself.
            free( T );
        
            ToNextItem();
        }
    
        RevertToList();
    }
    
    // Delete the list and items.
    DeleteList( AGraph->Labels );
    
    // Free the line graph record itself.
    free( AGraph );
}

/*------------------------------------------------------------
| DrawDataSeries
|-------------------------------------------------------------
|
| PURPOSE: To draw a data series in the data area of a 
|          line graph.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.28.96 
------------------------------------------------------------*/
void
DrawDataSeries( DataSeries* ASeries )
{
    s16         h,v,PtRad; 
    f64     yscale, xscale;
    f64     wxmin, wxmax, wymin, wymax;
    f64     dxmin, dxmax, dymin, dymax;
    f64     x,y;
    s32         RowCount;
    s32         i;
    LineGraph*  AGraph;
    f64*        X;
    f64*        Y;
    s16*        W;
    Rect        PtRect;
    u32         IsX, IsY;
    
    // Set the line color.
    RGBForeColor( &ASeries->LineColor );

    // Refer to the graph.
    AGraph = ASeries->Graph;
    
    // Get the coord transform data for speed later.
    wxmin = (f64) AGraph->DataArea.left;
    wxmax = (f64) AGraph->DataArea.right;
    wymin = (f64) AGraph->DataArea.top;
    wymax = (f64) AGraph->DataArea.bottom;
    
    dxmin = AGraph->XMin;
    dxmax = AGraph->XMax;
    dymin = AGraph->YMin;
    dymax = AGraph->YMax;

    // Calculate the scaling factors for the data to screen
    // coords.
    yscale =  ( wymax - wymin ) /
              ( dymax - dymin );
          
    xscale =  ( wxmax - wxmin ) /
              ( dxmax - dxmin );

    // Get which dimensions are present.
    IsX = ASeries->Data->IsX;
    IsY = ASeries->Data->IsY;
    RowCount = ASeries->Data->ItemCount;
    
    // Refer to the data.
    X = ASeries->Data->X;
    Y = ASeries->Data->Y;
    
    // Refer to the window coordinate point space.
    W = ASeries->WinPt;
    
    // Get the first point in the data.
    if( IsX ) { x = X[0]; } else { x = dxmin; }
    if( IsY ) { y = Y[0]; } else { y = dymin; }
        
    // Convert to window coordinates.
    h = ((x - dxmin) * xscale) + wxmin;
    v = wymax - ((y - dymin) * yscale);
    
    // Save the window coordinate.
    *W++ = h;
    *W++ = v;
    
    // Set the starting pen location.
    MoveTo( h, v );
    
    // If points are drawn, draw point.
    if( ASeries->IsPointsDrawn )
    {
        PtRad = (s16) ASeries->PointRadius;

        PtRect.left   = max(h - PtRad,wxmin);
        PtRect.right  = min(h + PtRad,wxmax);
        PtRect.top    = max(v - PtRad,wymin);
        PtRect.bottom = min(v + PtRad,wymax);
        
        PaintOval( &PtRect );
    }
        
    // For each subsequent point.
    for( i = 1; i < RowCount; i++ )
    {
        // Get the next point in the data.
        if( IsX ) { x = X[i]; } else { x = (f64) (i + dxmin); }
        if( IsY ) { y = Y[i]; } else { y = (f64) (i + dymin); }
        
        // Convert to window coordinates.
        h = ((x - dxmin) * xscale) + wxmin;
        v = wymax - ((y - dymin) * yscale);
    
        // Save the window coordinate.
        *W++ = h;
        *W++ = v;
        
        // Draw a line from the last point to this one,
        // if lines should be connected.
        if( ASeries->IsConnected )
        {
            LineTo( h, v );
        }
            
        // If points are drawn, draw point.
        if( ASeries->IsPointsDrawn )
        {
            PtRect.left   = max(h - PtRad,wxmin);
            PtRect.right  = min(h + PtRad,wxmax);
            PtRect.top    = max(v - PtRad,wymin);
            PtRect.bottom = min(v + PtRad,wymax);
        
            PaintOval( &PtRect );
        }
#ifdef SLOWMO
        // For slow-mo drawing of points.
        {
            s32     j;
            for( j = 1; j < 1000000; j++ ); // Delay
        }
#endif
    }
}

/*------------------------------------------------------------
| DrawFilledRectangle
|-------------------------------------------------------------
|
| PURPOSE: To draw a filled rectangle of a certain color.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 02.27.96
|          03.02.98 pulled out setting of the graphics port. 
------------------------------------------------------------*/
void
DrawFilledRectangle( Rect* ARect, RGBColor* AColor )
{
    // Make this the active port for drawing.
//  SetPort( TheGraphicsWindow );                        
    
    // Set the fill color.
    RGBForeColor( AColor );
    
    // Draw the rectangle.
    PaintRect( ARect );
}       

/*------------------------------------------------------------
| DrawGraph
|-------------------------------------------------------------
|
| PURPOSE: To draw the frame and labeling of a line graph
|          as well as all of its data series.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.28.96 
------------------------------------------------------------*/
void
DrawGraph( LineGraph* AGraph )
{
    Rect    ARect;
    
    // If the data space extents are all zero, then call
    // the 'AutoScaleLineGraphSquare' procedure.
    if( AGraph->XMin == 0 &&
        AGraph->XMax == 0 &&
        AGraph->YMin == 0 &&
        AGraph->YMax == 0 )
    {
        AutoScaleLineGraphSquare( AGraph );
    }

    // Fill the graph with the background color.
    if( AGraph->IsBackground )
    {
        DrawFilledRectangle( &AGraph->FullArea, 
                             &AGraph->FillColor );
    }
                        
    // Draw the border, if any.
    if( AGraph->IsBorder )
    {
        PenSize( (s16) AGraph->BorderLineWidth,
                 (s16) AGraph->BorderLineWidth );
             
        DrawRectangle( &AGraph->FullArea, 
                       &AGraph->BorderColor );
    }
    
    // Draw the data area border, if any.
    if( AGraph->IsDataBorder )
    {
        PenSize( (s16) AGraph->BorderLineWidth,
                 (s16) AGraph->BorderLineWidth );
        
        ARect = AGraph->DataArea;
        InsetRect( &ARect, -1, -1 );
        DrawRectangle( &ARect, 
                       &AGraph->BorderColor );
    }
        
    // Draw the title, if any.
    if( AGraph->Title[0] )
    {
        // Center at the top.
        
        DrawStringCenteredAt( 
               ( ( AGraph->FullArea.right -
                   AGraph->FullArea.left ) / 2 ) +
                AGraph->FullArea.left,
                AGraph->FullArea.top + 2,
                AGraph->Title );
    }
    
    // Draw the x axis, if any.
    if( AGraph->IsXAxis )
    {
        PenSize( (s16) AGraph->BorderLineWidth,
                 (s16) AGraph->BorderLineWidth );
        
        MoveTo( AGraph->DataArea.left-1,
                AGraph->DataArea.bottom );
        
        LineTo( AGraph->DataArea.right,
                AGraph->DataArea.bottom );
                
        // Draw the x axis label, if any.
        if( AGraph->XAxisLabel[0] )
        {
            // Draw in centered at bottom.
            DrawStringCenteredAt( 
               ( ( AGraph->DataArea.right -
                   AGraph->DataArea.left ) / 2 ) +
                AGraph->DataArea.left,
                AGraph->FullArea.bottom -
                (CurrentGraphFontHeight + 2),
                AGraph->XAxisLabel );
        }
    }
    
    // Draw the y axis, if any.
    if( AGraph->IsYAxis )
    {
        PenSize( (s16) AGraph->BorderLineWidth,
                 (s16) AGraph->BorderLineWidth );
        
        MoveTo( AGraph->DataArea.left-1,
                AGraph->DataArea.bottom );
        
        LineTo( AGraph->DataArea.left-1,
                AGraph->DataArea.top );
                
        // Draw the y axis label, if any.
        if( AGraph->YAxisLabel[0] )
        {
            // Draw centered in left margin.
        
            DrawVerticalStringCenteredAt( 
                AGraph->FullArea.left + 3,
               ( ( AGraph->DataArea.bottom -
                   AGraph->DataArea.top ) / 2 ) +
                AGraph->DataArea.top,
                AGraph->YAxisLabel );
        }
    }
    
    // Draw each data series.
    DrawLineGraphDataArea(AGraph);
}

/*------------------------------------------------------------
| DrawLineGraphDataArea
|-------------------------------------------------------------
|
| PURPOSE: To draw the data area of a line graph.
|
| DESCRIPTION: Call this routine any time data series data
|              changes.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.28.96 
|          05.22.96 added 'IsBackground'.
------------------------------------------------------------*/
void
DrawLineGraphDataArea( LineGraph* AGraph )
{
    // Fill the graph data area with the background color.
    if( AGraph->IsBackground )
    {
        DrawFilledRectangle( &AGraph->DataArea, 
                             &AGraph->FillColor );
    }
    
    // Draw each data series.
    DrawLineGraphDataSeries( AGraph );
    
    // Draw each text label.
    DrawGraphTextLabels( AGraph );
}

/*------------------------------------------------------------
| DrawLineGraphDataSeries
|-------------------------------------------------------------
|
| PURPOSE: To draw the data series of a line graph.
|
| DESCRIPTION: Call this routine any time data series data
|              changes, after erasing the old data series
|              individually.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.02.96 
------------------------------------------------------------*/
void
DrawLineGraphDataSeries( LineGraph* AGraph )
{
    // Draw each data series.
    ReferToList( AGraph->Data ); 
    
    while( TheItem )
    {
        DrawDataSeries( (DataSeries*) TheDataAddress );
        ToNextItem();
    }
    
    RevertToList();
}
    
/*------------------------------------------------------------
| DrawStringAt
|-------------------------------------------------------------
|
| PURPOSE: To draw a string at a certain place on the current 
|          graphics window.
|
| DESCRIPTION: Set the graphics window as current and then
| draws a white rectangle and then writes the given text in 
| black.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 02.26.96 
|          12.11.96 fixed '%c' and added '%s'
|          02.24.98 added size spec parsing.
------------------------------------------------------------*/
void
DrawStringAt( s32 x, s32 y, s8* Format, ... )
{
    Rect    ARect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};
    s8      SprintfIn[256];  
    s8      SprintfOut[256]; 
    s8      FinalString[256]; 
    s8      AByte;
    s8*     In;
    va_list ap;
    
    // Clear the final string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
                
            if( ! IsLetter( AByte ) )
            {
                goto BuildFormattingSection;
            }
            
            // The byte is a letter it may be a size specification,
            // one fo the characters: 'l', 'L' or 'h'.
            //
            // If a size specification.
            if( AByte == 'l' ||
                AByte == 'L' ||
                AByte == 'h' )
            {
                // Get next byte.
                AByte = *Format++;
            
                // Feed byte to sprintf input buffer.
                *In++ = AByte;
            }
                    
            // If byte is a letter, then we have reached
            // the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) ); // chars take 4 bytes on the
                                                  // stack.
                    break;
                }
                
                // String
                case 's':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,f64) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            AppendString2( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        AppendString2( FinalString, SprintfOut );
    }
                    
    // Figure out the dimensions of the text rectangle.
    ARect = *TextRect( x, y, FinalString );
    
    // This also sets the active port for drawing.
    DrawFilledRectangle( &ARect, &White );
        
    // Set the fill color to black.
    RGBForeColor( &Black );
    
    // Set the current pen position.            
    MoveTo( x, y + CurrentGraphFontHeight );

    // Convert the string to Pascal format.
    c2pstr( (char*) FinalString ); 
    
    // Draw the string.
    DrawString( (u8*) FinalString );
    
    va_end( ap );
}

/*------------------------------------------------------------
| DrawStringCenteredAt
|-------------------------------------------------------------
|
| PURPOSE: To draw a string centered horizontally at a 
|          certain place on the current graphics window.
|
| DESCRIPTION: Set the graphics window as current and then
| draws a white rectangle and then writes the given text in 
| black.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 02.28.96 from 'DrawStringAt'.
|          12.11.96 fixed '%c' and added '%s'.
|          02.24.98 added size spec parsing.
------------------------------------------------------------*/
void
DrawStringCenteredAt( s32 x, s32 y, s8* Format, ... )
{
    Rect    ARect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};
    s16     dx;
    s8      SprintfIn[256];  
    s8      SprintfOut[256]; 
    s8      FinalString[256]; 
    s8      AByte;
    s8*     In;
    va_list ap;
    
    // Clear the final string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
                
            if( ! IsLetter( AByte ) )
            {
                goto BuildFormattingSection;
            }
                
            // The byte is a letter it may be a size specification,
            // one fo the characters: 'l', 'L' or 'h'.
            //
            // If a size specification.
            if( AByte == 'l' ||
                AByte == 'L' ||
                AByte == 'h' )
            {
                // Get next byte.
                AByte = *Format++;
            
                // Feed byte to sprintf input buffer.
                *In++ = AByte;
            }
                    
            // If byte is a letter, then we have reached
            // the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) ); // chars take 4 bytes on the
                                               // stack.
                    break;
                }
                
                // String
                case 's':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,f64) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            AppendString2( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        AppendString2( FinalString, SprintfOut );
    }
                    
    // Figure out the dimensions of the text rectangle.
    ARect = *TextRect( x, y, FinalString );
    
    // Center the text rectangle on x, y.
    dx = (ARect.right - ARect.left) / 2;
    ARect.left  -= dx;
    ARect.right -= dx;
    
    // This also sets the active port for drawing.
    DrawFilledRectangle( &ARect, &White );
        
    // Set the fill color to black.
    RGBForeColor( &Black );
    
    // Set the current pen position.            
    MoveTo( ARect.left, y + CurrentGraphFontHeight );

    // Convert the string to Pascal format.
    c2pstr( (char*) FinalString ); 
    
    // Draw the string.
    DrawString( (u8*) FinalString );
    
    va_end( ap );
}

/*------------------------------------------------------------
| DrawStringOnLine
|-------------------------------------------------------------
|
| PURPOSE: To draw a string at a certain place on the current 
|          graphics window, clearing the entire line to the
|          right.
|
| DESCRIPTION: Clears the line from the point to the right
| hand of graphics window and then writes the given text in 
| black.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 02.27.96 
|          12.11.96 fixed '%c' and added '%s'.
|          01.09.97 added 'ProcessPendingEvent'.
|          02.24.98 added size spec parsing.
------------------------------------------------------------*/
void
DrawStringOnLine( s32 x, s32 y, s8* Format, ... )
{
    s8      SprintfIn[256];  
    s8      SprintfOut[256]; 
    s8      FinalString[256]; 
    s8      AByte;
    s8*     In;
    va_list ap;

    // Clear the final string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // 
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
                
            if( ! IsLetter( AByte ) )
            {
                goto BuildFormattingSection;
            }
                
            // The byte is a letter it may be a size specification,
            // one fo the characters: 'l', 'L' or 'h'.
            //
            // If a size specification.
            if( AByte == 'l' ||
                AByte == 'L' ||
                AByte == 'h' )
            {
                // Get next byte.
                AByte = *Format++;
            
                // Feed byte to sprintf input buffer.
                *In++ = AByte;
            }
                    
            // If byte is a letter, then we have reached
            // the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) ); // chars take 4 bytes on the
                                               // stack.
                    break;
                }
                
                // String
                case 's':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,f64) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            AppendString2( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        AppendString2( FinalString, SprintfOut );
    }
                    
    // This also sets the active port for drawing.
    ClearTextLine( x, y );
        
    // Set the fill color to black.
    RGBForeColor( &Black );
    
    // Set the current pen position.            
    MoveTo( x, y + CurrentGraphFontHeight );

    // Convert the string to Pascal format.
    c2pstr((char*) FinalString); 
    
    // Draw the string.
    DrawString( (u8*) FinalString );
    
    va_end( ap );
}

/*------------------------------------------------------------
| DrawVerticalStringCenteredAt
|-------------------------------------------------------------
|
| PURPOSE: To draw a string centered vertically at a 
|          certain place on the current graphics window.
|
| DESCRIPTION: Set the graphics window as current and then
| draws a white rectangle and then writes the given text in 
| black.  
|
| The text origin is to the left of the text and
| vertically centered like this:
|
|               -----
|               | A |
|         (x,y) + A |
|               | A |
|               -----
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 02.28.96 from 'DrawStringAt'.
------------------------------------------------------------*/
void
DrawVerticalStringCenteredAt( s32 x, s32 y, s8* Format, ... )
{
    Rect    ARect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};
    s16     dy;
    s16     TextYOffset;
    s8      SprintfIn[256];  
    s8      SprintfOut[256]; 
    s8      FinalString[256]; 
    s8      AByte;
    s8*     In;
    s8*     c;
    va_list ap;
    
    // Clear the final string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
                
            if( ! IsLetter( AByte ) )
            {
                goto BuildFormattingSection;
            }
                
            // If byte is a letter, then we have reached
            // the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s8) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,f64) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            AppendString2( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        AppendString2( FinalString, SprintfOut );
    }
                    
    // Figure out the dimensions of the text rectangle.
    ARect = *VerticalTextRect( x, y, FinalString );
    
    // Center the text rectangle on x, y.
    dy = (ARect.bottom - ARect.top) / 2;
    ARect.top    += dy;
    ARect.bottom += dy;
    
    // This also sets the active port for drawing.
    DrawFilledRectangle( &ARect, &White );
        
    // Set the fill color to black.
    RGBForeColor( &Black );
    
    // For each character.
    c = &FinalString[0];
    TextYOffset = ARect.top + DefaultTextTopToBaseLine;
    while( *c )
    {
        // Set the current pen position.            
        MoveTo( ARect.left, TextYOffset );

        // Draw the character.
        DrawChar( *c++ );
        
        // Move down to next character position.
        TextYOffset += CurrentGraphFontHeight;
    }
    
    va_end( ap );
}

/*------------------------------------------------------------
| DrawMatrix
|-------------------------------------------------------------
|
| PURPOSE: To draw a pixel map representing any
|          matrix on the current graphics window.
|
| DESCRIPTION: Draws an optional title followed by a color
| mapped image of a matrix.  The layout is like this:
|
|        (x,y)
|        |
|        *<Title>
|        --------------
|        |            |
|        |            |
|        --------------
|
| The minimum and maximum values in the matrix are used to
| set the extremes of the color map.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 02.26.96 
------------------------------------------------------------*/
void
DrawMatrix( Matrix* AMatrix, 
            s8* Title, // 0 if none.
            s32 x, 
            s32 y,
            s32 XPixelsPerCell,
            s32 YPixelsPerCell )
{
    Rect        CellRect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};

    s32         RowCount;
    s32         ColCount;
    s32         r,c;
    RGBColor    CellColor;
    f64**       A;
    f64         AMin;
    f64         AMax;

    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Refer to the matrix specifications.
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    A        = (f64**) AMatrix->a;

    // Find the extreme values in the matrix.
    GetMatrixExtremes( AMatrix, &AMin, &AMax );
    
    // If there is a title, draw it.
    if( Title )
    {
        DrawStringAt( x, y, Title );
        
        // Start at the top row of the matrix.
        CellRect.top  = y + 2 + CurrentGraphFontHeight;
    }
    else // No title.
    {
        // Start at the top row of the matrix.
        CellRect.top  = y;
    }
    
    // For each cell.
    for( r = 0; r < RowCount; r++ )
    {
        // Start at left column.
        CellRect.left = x;
        
        for( c = 0; c < ColCount; c++ )
        {
            // Find the color that cooresponds to the
            // cell value.
            MapValueToColor( A[r][c], 
                             AMin, 
                             AMax,
                             &CellColor );
            
            // Set the current color to that value.
            RGBForeColor( &CellColor );

            // Complete the dimensions of the rectangle
            // that will be used to represent the cell.
            CellRect.bottom = CellRect.top + 
                              YPixelsPerCell;
                              
            CellRect.right = CellRect.left + 
                              XPixelsPerCell;
            
            // Set the current pen position.            
//          MoveTo( CellRect.left, CellRect.top );
            
            // Draw the rectangle.
            PaintRect( &CellRect );
            
            // Advance the position to the next column.
            CellRect.left += XPixelsPerCell;
        }
        
        // Advance the position to the next row.
        CellRect.top += YPixelsPerCell;
    }
}       

/*------------------------------------------------------------
| DrawProbabilityMatrix
|-------------------------------------------------------------
|
| PURPOSE: To draw a pixel map representing a probability 
|          matrix on the current graphics window.
|
| DESCRIPTION: Draws an optional title followed by a color
| mapped image of a matrix.  The layout is like this:
|
|        (x,y)
|        |
|        *<Title>
|        --------------
|        |            |
|        |            |
|        --------------
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 02.26.96 
------------------------------------------------------------*/
void
DrawProbabilityMatrix( Matrix* AMatrix, 
                       s8* Title, // 0 if none.
                       s32 x, 
                       s32 y,
                       s32 XPixelsPerCell,
                       s32 YPixelsPerCell )
{
    Rect        CellRect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};

    s32         RowCount;
    s32         ColCount;
    s32         r,c;
    RGBColor    CellColor;
    f64**       A;

    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Refer to the matrix specifications.
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    A        = (f64**) AMatrix->a;

    // If there is a title, draw it.
    if( Title )
    {
        DrawStringAt( x, y, Title );
        
        // Start at the top row of the matrix.
        CellRect.top  = y + 2 + CurrentGraphFontHeight;
    }
    else // No title.
    {
        // Start at the top row of the matrix.
        CellRect.top  = y;
    }
    
    // For each cell.
    for( r = 0; r < RowCount; r++ )
    {
        // Start at left column.
        CellRect.left = x;
        
        for( c = 0; c < ColCount; c++ )
        {
            // Find the color that cooresponds to the
            // cell value.
            MapProbabilityToColor( A[r][c], &CellColor );
            
            // Set the current color to that value.
            RGBForeColor( &CellColor );

            // Complete the dimensions of the rectangle
            // that will be used to represent the cell.
            CellRect.bottom = CellRect.top + 
                              YPixelsPerCell;
                              
            CellRect.right = CellRect.left + 
                              XPixelsPerCell;
            
            // Set the current pen position.            
            MoveTo( CellRect.left, CellRect.top );
            
            // Draw the rectangle.
            PaintRect( &CellRect );
            
            // Advance the position to the next column.
            CellRect.left += XPixelsPerCell;
        }
        
        // Advance the position to the next row.
        CellRect.top += YPixelsPerCell;
    }
}

/*------------------------------------------------------------
| DrawProbabilityMatrix2
|-------------------------------------------------------------
|
| PURPOSE: To draw a pixel map representing a probability 
|          matrix on the current graphics window.
|
| DESCRIPTION: Same as 'DrawProbabilityMatrix' but the color
| map is focused on the area between .45 and .55.
|
| Draws an optional title followed by a color
| mapped image of a matrix.  The layout is like this:
|
|        (x,y)
|        |
|        *<Title>
|        --------------
|        |            |
|        |            |
|        --------------
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 05.22.96 from 'DrawProbabilityMatrix'.
------------------------------------------------------------*/
#if 0
void
DrawProbabilityMatrix2( Matrix* AMatrix, 
                       s8* Title, // 0 if none.
                       s32 x, 
                       s32 y,
                       s32 XPixelsPerCell,
                       s32 YPixelsPerCell )
{
    Rect        CellRect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};

    s32         RowCount;
    s32         ColCount;
    s32         r,c;
    RGBColor    CellColor;
    f64**       A;

    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Refer to the matrix specifications.
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    A        = AMatrix->a;

    // If there is a title, draw it.
    if( Title )
    {
        DrawStringAt( x, y, Title );
        
        // Start at the top row of the matrix.
        CellRect.top  = y + 2 + CurrentGraphFontHeight;
    }
    else // No title.
    {
        // Start at the top row of the matrix.
        CellRect.top  = y;
    }
    
    // For each cell.
    for( r = 0; r < RowCount; r++ )
    {
        // Start at left column.
        CellRect.left = x;
        
        for( c = 0; c < ColCount; c++ )
        {
            // Find the color that cooresponds to the
            // cell value.
            MapProbabilityToColor2( A[r][c], &CellColor );
            
            // Set the current color to that value.
            RGBForeColor( &CellColor );

            // Complete the dimensions of the rectangle
            // that will be used to represent the cell.
            CellRect.bottom = CellRect.top + 
                              YPixelsPerCell;
                              
            CellRect.right = CellRect.left + 
                              XPixelsPerCell;
            
            // Set the current pen position.            
            MoveTo( CellRect.left, CellRect.top );
            
            // Draw the rectangle.
            PaintRect( &CellRect );
            
            // Advance the position to the next column.
            CellRect.left += XPixelsPerCell;
        }
        
        // Advance the position to the next row.
        CellRect.top += YPixelsPerCell;
    }
}
#endif
void
DrawProbabilityMatrix2( Matrix* AMatrix, 
                       s8* Title, // 0 if none.
                       s32 x, 
                       s32 y,
                       s32 XPixelsPerCell,
                       s32 YPixelsPerCell )
{
    Rect        CellRect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};

    s32         RowCount;
    s32         ColCount;
    s32         r,c;
    RGBColor    CellColor;
    f64**       A;

    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Refer to the matrix specifications.
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    A        = (f64**) AMatrix->a;

    // If there is a title, draw it.
    if( Title )
    {
        DrawStringAt( x, y, Title );
        
        // Start at the top row of the matrix.
        CellRect.top  = y + 2 + CurrentGraphFontHeight;
    }
    else // No title.
    {
        // Start at the top row of the matrix.
        CellRect.top  = y;
    }
    
    // For each cell.
    for( r = 0; r < RowCount; r++ )
    {
        // Start at left column.
        CellRect.left = x;
        
        for( c = 0; c < ColCount; c++ )
        {
            // Find the color that cooresponds to the
            // cell value.
            MapProbabilityToColor( A[r][c], &CellColor );
            
            // Set the current color to that value.
            RGBForeColor( &CellColor );

            // Complete the dimensions of the rectangle
            // that will be used to represent the cell.
            CellRect.bottom = CellRect.top + 
                              YPixelsPerCell;
                              
            CellRect.right = CellRect.left + 
                              XPixelsPerCell;
            
            // Set the current pen position.            
            MoveTo( CellRect.left, CellRect.top );
            
            // Draw the rectangle.
            PaintRect( &CellRect );
            
            // Advance the position to the next column.
            CellRect.left += XPixelsPerCell;
        }
        
        // Advance the position to the next row.
        CellRect.top += YPixelsPerCell;
    }
}

/*------------------------------------------------------------
| DrawProbabilityMatrix3
|-------------------------------------------------------------
|
| PURPOSE: To draw a pixel map representing a probability 
|          matrix on the current graphics window.
|
| DESCRIPTION: Same as 'DrawProbabilityMatrix' but the color
| map is focused on the area between .495 and .505.
|
| Draws an optional title followed by a color
| mapped image of a matrix.  The layout is like this:
|
|        (x,y)
|        |
|        *<Title>
|        --------------
|        |            |
|        |            |
|        --------------
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 09.08.96 from 'DrawProbabilityMatrix2'.
------------------------------------------------------------*/
void
DrawProbabilityMatrix3( Matrix* AMatrix, 
                       s8* Title, // 0 if none.
                       s32 x, 
                       s32 y,
                       s32 XPixelsPerCell,
                       s32 YPixelsPerCell )
{
    Rect        CellRect;
//  struct Rect {
//  short   top;
//  short   left;
//  short   bottom;
//  short   right;
//};

    s32         RowCount;
    s32         ColCount;
    s32         r,c;
    RGBColor    CellColor;
    f64**       A;

    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Refer to the matrix specifications.
    RowCount = AMatrix->RowCount;
    ColCount = AMatrix->ColCount;
    A        = (f64**) AMatrix->a;

    // If there is a title, draw it.
    if( Title )
    {
        DrawStringAt( x, y, Title );
        
        // Start at the top row of the matrix.
        CellRect.top  = y + 2 + CurrentGraphFontHeight;
    }
    else // No title.
    {
        // Start at the top row of the matrix.
        CellRect.top  = y;
    }
    
    // For each cell.
    for( r = 0; r < RowCount; r++ )
    {
        // Start at left column.
        CellRect.left = x;
        
        for( c = 0; c < ColCount; c++ )
        {
            // Find the color that cooresponds to the
            // cell value.
            MapProbabilityToColor3( A[r][c], &CellColor );
            
            // Set the current color to that value.
            RGBForeColor( &CellColor );

            // Complete the dimensions of the rectangle
            // that will be used to represent the cell.
            CellRect.bottom = CellRect.top + 
                              YPixelsPerCell;
                              
            CellRect.right = CellRect.left + 
                              XPixelsPerCell;
            
            // Set the current pen position.            
            MoveTo( CellRect.left, CellRect.top );
            
            // Draw the rectangle.
            PaintRect( &CellRect );
            
            // Advance the position to the next column.
            CellRect.left += XPixelsPerCell;
        }
        
        // Advance the position to the next row.
        CellRect.top += YPixelsPerCell;
    }
}
                
                
/*------------------------------------------------------------
| DrawRectangle
|-------------------------------------------------------------
|
| PURPOSE: To draw a border rectangle of a certain color.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:
|           
| HISTORY: 02.28.96 
------------------------------------------------------------*/
void
DrawRectangle( Rect* ARect, RGBColor* AColor )
{
    // Make this the active port for drawing.
    SetPort( TheGraphicsWindow );                        
    
    // Set the fill color.
    RGBForeColor( AColor );
    
    // Draw the rectangle.
    FrameRect( ARect );
}       

/*------------------------------------------------------------
| DrawPoints
|-------------------------------------------------------------
|
| PURPOSE: To draw a vector of (x,y) points.
|
| DESCRIPTION: Generates a new 'LineGraph', plots the
| un-connected points in the given color, then discards the
| 'LineGraph' structure.
|
| Automatically scales the line graph to include all points.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.01.96 
------------------------------------------------------------*/
void
DrawPoints( Vector* V, Rect* ARect, RGBColor* AColor )
{
    LineGraph* AGraph;
    
    AGraph = MakeGraph( 0, ARect );

    AddPointsToGraph( AGraph, V, AColor );
    
    DrawGraph( AGraph );
    
    DeleteGraph( AGraph );
}
    
/*------------------------------------------------------------
| DrawGraphTextLabels
|-------------------------------------------------------------
|
| PURPOSE: To draw the text labels of a line graph.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.01.97
------------------------------------------------------------*/
void
DrawGraphTextLabels( LineGraph* AGraph )
{
    // Draw each label.
    ReferToList( AGraph->Labels ); 
    
    while( TheItem )
    {
        DrawTextLabel( (TextLabel*) TheDataAddress );
        ToNextItem();
    }
    
    RevertToList();
}
    
/*------------------------------------------------------------
| DrawTextLabel
|-------------------------------------------------------------
|
| PURPOSE: To draw a text label on a line graph.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.01.97 from 'DrawDataSeries'. 
------------------------------------------------------------*/
void
DrawTextLabel( TextLabel* T )
{
    s16         h,v; 
    f64     yscale, xscale;
    f64     wxmin, wxmax, wymin, wymax;
    f64     dxmin, dxmax, dymin, dymax;
    LineGraph*  G;
    Rect*       TextExtent;
    Rect        Align;
    
    // Refer to the graph.
    G = T->Graph;
    
    // If alignment is required.
    if( T->IsAlignToBox || T->IsAlignToPoint )
    {
        // Calculate the text extent for string as if it were
        // at (0,0).
        TextExtent = 
            CalculateTextExtent( 0, 0, T->Font, T->Text );
        
        // If aligning to a box.
        if( T->IsAlignToBox )
        {
            // Align to the given alignment box.
            AlignRectToRect( TextExtent, 
                             &T->AlignmentBox,
                             T->AlignmentCode );
        }
        else // Aligning to a data point.
        {
            dxmin = G->XMin;
            dxmax = G->XMax;
            dymin = G->YMin;
            dymax = G->YMax;

            // Get the coord transform data.
            wxmin = (f64) G->DataArea.left;
            wxmax = (f64) G->DataArea.right;
            wymin = (f64) G->DataArea.top;
            wymax = (f64) G->DataArea.bottom;
    
            // Calculate the scaling factors for the data to 
            // image space coords.
            yscale = ( wymax - wymin ) /
                     ( dymax - dymin );
          
            xscale = ( wxmax - wxmin ) /
                     ( dxmax - dxmin );

            // Convert the data point to image space coords.
            h = ((T->DataX - dxmin) * xscale) + wxmin;
            v = wymax - ((T->DataY - dymin) * yscale);
            
            // Make an alignment box centered on the point
            // with a radius as given.
            Align.top    = v - T->RadiusFromDataPoint;
            Align.bottom = v + T->RadiusFromDataPoint;
            Align.left   = h - T->RadiusFromDataPoint;
            Align.right  = h + T->RadiusFromDataPoint;
            
            // Align to the radial box.
            AlignRectToRect( TextExtent, 
                             &Align,
                             T->AlignmentCode );
        }
        
        // Copy the text extent to the record.
        T->TextExtent = *TextExtent;
    }
    // else // Text extent is taken as given.
    
    // Calculate the border extent.
    T->BorderExtent = T->TextExtent;
    InsetRect( &T->BorderExtent, -2, -2 );
    T->BorderExtent.right -= 1;
    
    // If there is a line to the data point, draw it.
    if( T->IsLineToDataPoint )
    {
        // Set the color of the indicator line.
        RGBForeColor( &T->BorderColor );
        
        // Position the pen at the data point image
        // space point.
        MoveTo( h, v );
        
        // Draw line to the center of the text extent.
        h = (T->TextExtent.right +
                 T->TextExtent.left) / 2;
        v = (T->TextExtent.bottom +
                 T->TextExtent.top) / 2;
    
        LineTo( h, v );
    }

    // If there is a background, fill it.
    if( T->IsBackground )
    {
        DrawFilledRectangle( &T->BorderExtent, 
                             &T->BackgroundColor );
    }
            
    // If there is a border, draw it.
    if( T->IsBorder )
    {
        DrawRectangle( &T->BorderExtent, &T->BorderColor );
    }
    
    
    // Set the color of the text.
    RGBForeColor( &T->TextColor );
    
    // Set the current pen position.            
    MoveTo( T->TextExtent.left, 
            T->TextExtent.top + 
            T->Font->FontHeight );

    // Convert the string to Pascal format.
    c2pstr( (char*) T->Text ); 
    
    // Draw the text.
    DrawString( (u8*) T->Text );
        
    // Convert the string back to C format.
    p2cstr( (u8*) T->Text ); 
}

/*------------------------------------------------------------
| EraseDataSeries
|-------------------------------------------------------------
|
| PURPOSE: To erase a data series in the data area of a 
|          line graph.
|
| DESCRIPTION: Draws over the data series using the background
|              color.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Graphics window is current port.
|           
| HISTORY: 03.02.96 
------------------------------------------------------------*/
void
EraseDataSeries( DataSeries* ASeries )
{
    s16         h,v,PtRad; 
    f64     wxmin, wxmax, wymin, wymax;
    s32         RowCount;
    s32         i;
    LineGraph*  AGraph;
    s16*        W;
    Rect        PtRect;
    
    // Refer to the graph.
    AGraph = ASeries->Graph;

    // Set the line color to the graph background color.
    RGBForeColor( &AGraph->FillColor );

    // Get the window boundaries for speed later.
    wxmin = (f64) AGraph->DataArea.left;
    wxmax = (f64) AGraph->DataArea.right;
    wymin = (f64) AGraph->DataArea.top;
    wymax = (f64) AGraph->DataArea.bottom;

    // Get how many points there are.
    RowCount = ASeries->Data->ItemCount;
    
    // Refer to the window coordinate point space.
    W = ASeries->WinPt;
    
    // Get the first window coordinate.
    h = *W++;
    v = *W++;
    
    // Set the starting pen location.
    MoveTo( h, v );
    
    // If points are drawn, draw point.
    if( ASeries->IsPointsDrawn )
    {
        PtRad = (s16) ASeries->PointRadius;

        PtRect.left   = max(h - PtRad,wxmin);
        PtRect.right  = min(h + PtRad,wxmax);
        PtRect.top    = max(v - PtRad,wymin);
        PtRect.bottom = min(v + PtRad,wymax);
        
        PaintOval( &PtRect );
    }
        
    // For each subsequent point.
    for( i = 1; i < RowCount; i++ )
    {
        // Get the next point.
        h = *W++;
        v = *W++;
                
        // Draw a line from the last point to this one,
        // if lines should be connected.
        if( ASeries->IsConnected )
        {
            LineTo( h, v );
        }
            
        // If points are drawn, draw point.
        if( ASeries->IsPointsDrawn )
        {
            PtRect.left   = max(h - PtRad,wxmin);
            PtRect.right  = min(h + PtRad,wxmax);
            PtRect.top    = max(v - PtRad,wymin);
            PtRect.bottom = min(v + PtRad,wymax);
        
            PaintOval( &PtRect );
        }
    }
}

/*------------------------------------------------------------
| InitializeColorConstants
|-------------------------------------------------------------
|
| PURPOSE: To set the values of the color constants.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: These color values come from Inside Mac V-69.
|
| ASSUMES:  
|
| HISTORY: 02.27.96 
------------------------------------------------------------*/
void
InitializeColorConstants()
{ 
    Black.red   = 0x0000; Black.green   = 0x0000; Black.blue   = 0x0000;
    Yellow.red  = 0xfc00; Yellow.green  = 0xf37d; Yellow.blue  = 0x052f;
    Magenta.red = 0xf2d7; Magenta.green = 0x0856; Magenta.blue = 0x84ec;
    Red.red     = 0xdd6b; Red.green     = 0x08c2; Red.blue     = 0x06a2;
    Cyan.red    = 0x0241; Cyan.green    = 0xab54; Cyan.blue    = 0xeaff;
    Green.red   = 0x0000; Green.green   = 0x8000; Green.blue   = 0x11b0;
    Blue.red    = 0x0000; Blue.green    = 0x0000; Blue.blue    = 0xd400;
    White.red   = 0xffff; White.green   = 0xffff; White.blue   = 0xffff;

    // A mixture of red & yellow: 50% of each.
    Orange.red      = 0xecb5; 
    Orange.green    = 0x7e1f;  
    Orange.blue     = 0x05e8; 
}

/*------------------------------------------------------------
| MakeDataSeries
|-------------------------------------------------------------
|
| PURPOSE: To create a data series to appear on a line graph.
|
| DESCRIPTION: Dynamically allocates a 'DataSeries' record
| and adds to the given line graph.  The data series record
| will there after be managed by the line graph for purposes
| of deallocation.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: The data itself will remain over the life of the
|          graph and will be deallocated by the user.
|           
| HISTORY: 02.27.96 
------------------------------------------------------------*/
DataSeries*
MakeDataSeries( LineGraph* AGraph, 
                  s8*        Name, // Or '0' if no name.
                  Vector*    Data,
                  RGBColor*  LineColor )
{
    DataSeries* ASeries;
    
    // Create the data series record.
    ASeries = (DataSeries*) malloc( sizeof( DataSeries ) );
    
    // Copy the name of the data series to the record if
    // there is one.
    if( Name )
    {
        CopyString(  Name, (s8*) &ASeries->Name );
    }
    else
    {
        ASeries->Name[0] = 0;
    }
    
    // Link the data series to the line graph.
    ASeries->Graph = AGraph;
    
    // Refer to the data.
    ASeries->Data = Data;
    
    // Allocate memory for the window coordinates.
    ASeries->WinPt = (s16*) 
        malloc( Data->ItemCount * 2 * sizeof(s16) );
    
    // Record the line color.
    ASeries->LineColor = *LineColor;
    
    // Set the line width to default.
    ASeries->LineWidth = 1.0;
    
    // Set other defaults.
    ASeries->IsConnected = 1;
    ASeries->IsPointsDrawn = 0;
    ASeries->PointRadius = 1.0;
    
    // Append the data series to the list in the line graph.
    InsertDataLastInList( AGraph->Data, (u8*) ASeries );
    
    return( ASeries );
}

/*------------------------------------------------------------
| MakeGraph
|-------------------------------------------------------------
|
| PURPOSE: To create a line graph record.
|
| DESCRIPTION: Dynamically allocates a 'LineGraph' record
| and sets default values.
|
| The 'xmin'...'ymax' values are all set to 0 so that 
| 'AutoScaleLineGraph' will be applied to display all the
| data as the default.
|
| Set 'Title' to 0 if there is none.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.28.96 
|          03.25.96 added tick marks and labels.
|          04.01.96 pulled out data space extent parameters.
|          05.07.96 added setting of default axis labels.
|          05.22.96 added 'IsBackground' initialization.
|          01.29.97 added creation of label list.
------------------------------------------------------------*/
LineGraph*
MakeGraph( s8* Title, Rect* ARect )
{
    LineGraph* AGraph;
    
    // Create the line graph record.
    AGraph = (LineGraph*) malloc( sizeof( LineGraph ) );
    
    // Copy the title of the graph to the record if
    // there is one.
    if( Title )
    {
        CopyString( Title, (s8*) &AGraph->Title );
    }
    else
    {
        AGraph->Title[0] = 0;
    }
    
    // Copy the window extent to the record.
    AGraph->FullArea = *ARect;
    
    // Inset the data area to allow for title and axis
    // labels.
    AGraph->DataArea = *ARect;
    InsetRect( &AGraph->DataArea, 15, 15 );
    
    // Set the data space extents to 0 so that the autoscale
    // function will be applied later.
    AGraph->XMin = 0;
    AGraph->YMin = 0;
    AGraph->XMax = 0;
    AGraph->YMax = 0;
    
    // Set defaults.
    AGraph->IsBackground    = 1;
    AGraph->IsBorder        = 1;
    AGraph->IsDataBorder    = 1;
    AGraph->IsDataSpaceBorder = 1;
    AGraph->FillColor       = White;
    AGraph->BorderColor     = Black;
    AGraph->BorderLineWidth = 1.0;
    AGraph->IsXAxis         = 1;
    AGraph->IsYAxis         = 1;
    AGraph->IsXGrid         = 0;
    AGraph->IsYGrid         = 0;
    AGraph->IsXTickMarks    = 0;
    AGraph->IsYTickMarks    = 0;
    AGraph->IsXTickLabels   = 0;
    AGraph->IsYTickLabels   = 0;
    AGraph->XTickFormat[0]  = 0;
    AGraph->YTickFormat[0]  = 0;
    
    AGraph->GridLineWidth   = 1.0;
    AGraph->XGridDelta      = 1.0;
    AGraph->YGridDelta      = 1.0;
    AGraph->XAxisLabel[0]   = 'X';
    AGraph->XAxisLabel[1]   = 0;
    AGraph->YAxisLabel[0]   = 'Y';
    AGraph->YAxisLabel[1]   = 0;
    
    // Allocate a list for the data series.
    AGraph->Data = MakeList();
    
    // Allocate a list for the text labels.
    AGraph->Labels = MakeList();

    return( AGraph );
}

/*------------------------------------------------------------
| MakeTextLabel
|-------------------------------------------------------------
|
| PURPOSE: To make a text label record for a data point.
|
| DESCRIPTION: Duplicates the given string making it a 
| dependent record of a new 'TextLabel' record.
|
| Sets default parameters which can be altered be for 
| drawing.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Text may be changed between updates.
|           
| HISTORY: 02.01.97 
------------------------------------------------------------*/
TextLabel*
MakeTextLabel( f64 DataX, f64 DataY, s8* Text )
{
    TextLabel*  T;
    
    // Allocate the record.
    T = (TextLabel*) malloc( sizeof( TextLabel ) );
    
    // Clear the record.
    FillBytes( (u8*) T, sizeof( T ), 0 );
    
    // Preserve the text.
    T->Text = DuplicateString( Text );
    
    // Record the placement origin.
    T->DataX = DataX;
    T->DataY = DataY;
    
    // Set the defaults.
    T->Font                = &Monaco9;
    T->TextColor           = Black;
    T->BorderColor         = Black;
    T->BackgroundColor     = Yellow;
    T->AlignmentCode       = AlignTopLeft;
    T->IsAlignToBox        = 0;
    T->IsAlignToPoint      = 1;
    T->IsBackground        = 1;
    T->IsBorder            = 1;
    T->IsDataPointLabel    = 1;
    T->IsLineToDataPoint   = 1;
    T->LineWidth           = 1;
    T->RadiusFromDataPoint = 10;
    
    // Return the result.
    return( T );
}
    
/*------------------------------------------------------------
| MakeTint
|-------------------------------------------------------------
|
| PURPOSE: To make a new color by mixing white with another
|          color.
|
| DESCRIPTION: Values between 0 and 1.0 are used to control
| the mixture of white with a given color: 1.0 means use
| 100% of the color and no white.
|
|    0                     .5                       1.0
|    |----------------------|------------------------|
|   White                                        The Color
|
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.10.96 
------------------------------------------------------------*/
void 
MakeTint( RGBColor* FromColor, RGBColor* ToColor, f64 Density )
{
    f64 LimitX[2];
    f64 RedLimitY[2];
    f64 GrnLimitY[2];
    f64 BluLimitY[2];
    
    LimitX[0] = 0.;
    LimitX[1] = 1.;
    
    RedLimitY[0] = White.red;
    RedLimitY[1] = FromColor->red;
    GrnLimitY[0] = White.green;
    GrnLimitY[1] = FromColor->green;
    BluLimitY[0] = White.blue;
    BluLimitY[1] = FromColor->blue;
    
    ToColor->red = 
            InterpolateLinear( LimitX, RedLimitY, Density );
            
    ToColor->green = 
            InterpolateLinear( LimitX, GrnLimitY, Density );
            
    ToColor->blue  = 
            InterpolateLinear( LimitX, BluLimitY, Density );
}

/*------------------------------------------------------------
| MapProbabilityToColor
|-------------------------------------------------------------
|
| PURPOSE: To find the color that cooresponds to a probability 
|          value.
|
| DESCRIPTION: Values between 0 and 1.0 are mapped to this
| color map:
|
|    0         .4      .47  .5  .53    .6          1.0
|    |----------|-------|---|---|-------|------------|
|   Black      Blu    Cyan  Wt  Orange  Red        Black
|
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.26.96 
------------------------------------------------------------*/
void 
MapProbabilityToColor( f64 v, RGBColor* AColor )
{
    f64 RedLimitX[2],   RedLimitY[2];
    f64 GrnLimitX[2],   GrnLimitY[2];
    f64 BluLimitX[2],   BluLimitY[2];

    // For interpolation y is color, x is probability value.

    if( v < .5 )
    {  
        if( v < .47 )
        {
            if( v < .4 )
            {
                // Set the value limits.
                RedLimitX[0] = .4;          RedLimitX[1] = 0;       
                GrnLimitX[0] = .4;          GrnLimitX[1] = 0;     
                BluLimitX[0] = .4;          BluLimitX[1] = 0;    
            
                // Set the color limits.
                RedLimitY[0] = Blue.red;    RedLimitY[1] = Black.red;
                GrnLimitY[0] = Blue.green;  GrnLimitY[1] = Black.green;
                BluLimitY[0] = Blue.blue;   BluLimitY[1] = Black.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = .47;         RedLimitX[1] = .4;       
                GrnLimitX[0] = .47;         GrnLimitX[1] = .4;     
                BluLimitX[0] = .47;         BluLimitX[1] = .4;    
            
                // Set the color limits.
                RedLimitY[0] = Cyan.red;    RedLimitY[1] = Blue.red;
                GrnLimitY[0] = Cyan.green;  GrnLimitY[1] = Blue.green;
                BluLimitY[0] = Cyan.blue;   BluLimitY[1] = Blue.blue;
            }
        }
        else
        {
            // Set the value limits.
            RedLimitX[0] = .5;          RedLimitX[1] = .47;       
            GrnLimitX[0] = .5;          GrnLimitX[1] = .47;     
            BluLimitX[0] = .5;          BluLimitX[1] = .47;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Cyan.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Cyan.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Cyan.blue;
        }
    }
    else // Value more than .5.
    {
        if( v < .53 )
        {
            // Set the value limits.
            RedLimitX[0] = .5;          RedLimitX[1] = .53;       
            GrnLimitX[0] = .5;          GrnLimitX[1] = .53;     
            BluLimitX[0] = .5;          BluLimitX[1] = .53;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Orange.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Orange.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Orange.blue;
        }
        else
        {
            if( v < .6 )
            {
                // Set the value limits.
                RedLimitX[0] = .53;         RedLimitX[1] = .6;       
                GrnLimitX[0] = .53;         GrnLimitX[1] = .6;        
                BluLimitX[0] = .53;         BluLimitX[1] = .6;       
        
                // Set the color limits.
                RedLimitY[0] = Orange.red;      RedLimitY[1] = Red.red;
                GrnLimitY[0] = Orange.green;    GrnLimitY[1] = Red.green;
                BluLimitY[0] = Orange.blue;     BluLimitY[1] = Red.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = .6;          RedLimitX[1] = 1;       
                GrnLimitX[0] = .6;          GrnLimitX[1] = 1;        
                BluLimitX[0] = .6;          BluLimitX[1] = 1;       
        
                // Set the color limits.
                RedLimitY[0] = Red.red;     RedLimitY[1] = Black.red;
                GrnLimitY[0] = Red.green;   GrnLimitY[1] = Black.green;
                BluLimitY[0] = Red.blue;    BluLimitY[1] = Black.blue;
            } 
        }           
    }
    
    AColor->red = 
            InterpolateLinear( RedLimitX, RedLimitY, v );
    AColor->green = 
            InterpolateLinear( GrnLimitX, GrnLimitY, v );
    AColor->blue  = 
            InterpolateLinear( BluLimitX, BluLimitY, v );
}

/*------------------------------------------------------------
| MapProbabilityToColor2
|-------------------------------------------------------------
|
| PURPOSE: To find the color that cooresponds to a probability 
|          value.
|
| DESCRIPTION: Values between 0 and 1.0 are mapped to this
| color map:
|
|    0         .485   .495 .5   .505   .515          1
|    |----------|-------|---|---|-------|------------|
|   Black      Blu    Cyan  Wt  Orange  Red        Black
|    A          B       C   D   E       F            G
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 05.22.96 from 'MapProbabilityToColor2'.
|          06.19.96 optimized for 'AS50'.
------------------------------------------------------------*/
void 
MapProbabilityToColor2( f64 v, RGBColor* AColor )
{
    f64 RedLimitX[2],   RedLimitY[2];
    f64 GrnLimitX[2],   GrnLimitY[2];
    f64 BluLimitX[2],   BluLimitY[2];
    f64 A,B,C,D,E,F,G;

#ifdef SMALL_RANGE  
    A = 0;
    B = .485; // .46;
    C = .495; // .48;
    D = .5;
    E = .505; // .52;
    F = .515; // .54;
    G = 1.;
#else
    A = 0;
    B = .30;
    C = .40;
    D = .5;
    E = .60;
    F = .70;
    G = 1.;
//  A = 0;
//  B = .46;
//  C = .48;
//  D = .5;
//  E = .52;
//  F = .54;
//  G = 1.;
#endif  
    // For interpolation y is color, x is probability value.

    if( v < D )
    {  
        if( v < C )
        {
            if( v < B )
            {
                // Set the value limits.
                RedLimitX[0] = B;           RedLimitX[1] = A;       
                GrnLimitX[0] = B;           GrnLimitX[1] = A;     
                BluLimitX[0] = B;           BluLimitX[1] = A;    
            
                // Set the color limits.
                RedLimitY[0] = Blue.red;    RedLimitY[1] = Green.red;   // Black.red;
                GrnLimitY[0] = Blue.green;  GrnLimitY[1] = Green.green; // Black.green;
                BluLimitY[0] = Blue.blue;   BluLimitY[1] = Green.blue;  // Black.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = C;           RedLimitX[1] = B;       
                GrnLimitX[0] = C;           GrnLimitX[1] = B;     
                BluLimitX[0] = C;           BluLimitX[1] = B;    
            
                // Set the color limits.
                RedLimitY[0] = Cyan.red;    RedLimitY[1] = Blue.red;
                GrnLimitY[0] = Cyan.green;  GrnLimitY[1] = Blue.green;
                BluLimitY[0] = Cyan.blue;   BluLimitY[1] = Blue.blue;
            }
        }
        else
        {
            // Set the value limits.
            RedLimitX[0] = D;           RedLimitX[1] = C;       
            GrnLimitX[0] = D;           GrnLimitX[1] = C;     
            BluLimitX[0] = D;           BluLimitX[1] = C;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Cyan.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Cyan.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Cyan.blue;
        }
    }
    else // Value more than .5.
    {
        if( v < E )
        {
            // Set the value limits.
            RedLimitX[0] = D;           RedLimitX[1] = E;       
            GrnLimitX[0] = D;           GrnLimitX[1] = E;     
            BluLimitX[0] = D;           BluLimitX[1] = E;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Orange.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Orange.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Orange.blue;
        }
        else
        {
            if( v < F )
            {
                // Set the value limits.
                RedLimitX[0] = E;           RedLimitX[1] = F;       
                GrnLimitX[0] = E;           GrnLimitX[1] = F;        
                BluLimitX[0] = E;           BluLimitX[1] = F;       
        
                // Set the color limits.
                RedLimitY[0] = Orange.red;      RedLimitY[1] = Red.red;
                GrnLimitY[0] = Orange.green;    GrnLimitY[1] = Red.green;
                BluLimitY[0] = Orange.blue;     BluLimitY[1] = Red.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = F;           RedLimitX[1] = G;       
                GrnLimitX[0] = F;           GrnLimitX[1] = G;        
                BluLimitX[0] = F;           BluLimitX[1] = G;       
        
                // Set the color limits.
                RedLimitY[0] = Red.red;     RedLimitY[1] = Magenta.red; // Black.red;
                GrnLimitY[0] = Red.green;   GrnLimitY[1] = Magenta.green; // Black.green;
                BluLimitY[0] = Red.blue;    BluLimitY[1] = Magenta.blue; // Black.blue;
            } 
        }           
    }
    
    AColor->red = 
            InterpolateLinear( RedLimitX, RedLimitY, v );
    AColor->green = 
            InterpolateLinear( GrnLimitX, GrnLimitY, v );
    AColor->blue  = 
            InterpolateLinear( BluLimitX, BluLimitY, v );
}

/*------------------------------------------------------------
| MapProbabilityToColor3
|-------------------------------------------------------------
|
| PURPOSE: To find the color that cooresponds to a probability 
|          value.
|
| DESCRIPTION: Values between 0 and 1.0 are mapped to this
| color map:
|
|    0         .495   .498 .5   .502   .505          1
|    |----------|-------|---|---|-------|------------|
|   Black      Blu    Cyan  Wt  Orange  Red        Black
|    A          B       C   D   E       F            G
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 09.08.96 from 'MapProbabilityToColor2'.
------------------------------------------------------------*/
void 
MapProbabilityToColor3( f64 v, RGBColor* AColor )
{
    f64 RedLimitX[2],   RedLimitY[2];
    f64 GrnLimitX[2],   GrnLimitY[2];
    f64 BluLimitX[2],   BluLimitY[2];
    f64 A,B,C,D,E,F,G;

    A = 0;
    B = .495; 
    C = .498;  
    D = .5;
    E = .502; 
    F = .505; 
    G = 1.;

    // For interpolation y is color, x is probability value.

    if( v < D )
    {  
        if( v < C )
        {
            if( v < B )
            {
                // Set the value limits.
                RedLimitX[0] = B;           RedLimitX[1] = A;       
                GrnLimitX[0] = B;           GrnLimitX[1] = A;     
                BluLimitX[0] = B;           BluLimitX[1] = A;    
            
                // Set the color limits.
                RedLimitY[0] = Blue.red;    RedLimitY[1] = Green.red;   // Black.red;
                GrnLimitY[0] = Blue.green;  GrnLimitY[1] = Green.green; // Black.green;
                BluLimitY[0] = Blue.blue;   BluLimitY[1] = Green.blue;  // Black.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = C;           RedLimitX[1] = B;       
                GrnLimitX[0] = C;           GrnLimitX[1] = B;     
                BluLimitX[0] = C;           BluLimitX[1] = B;    
            
                // Set the color limits.
                RedLimitY[0] = Cyan.red;    RedLimitY[1] = Blue.red;
                GrnLimitY[0] = Cyan.green;  GrnLimitY[1] = Blue.green;
                BluLimitY[0] = Cyan.blue;   BluLimitY[1] = Blue.blue;
            }
        }
        else
        {
            // Set the value limits.
            RedLimitX[0] = D;           RedLimitX[1] = C;       
            GrnLimitX[0] = D;           GrnLimitX[1] = C;     
            BluLimitX[0] = D;           BluLimitX[1] = C;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Cyan.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Cyan.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Cyan.blue;
        }
    }
    else // Value more than .5.
    {
        if( v < E )
        {
            // Set the value limits.
            RedLimitX[0] = D;           RedLimitX[1] = E;       
            GrnLimitX[0] = D;           GrnLimitX[1] = E;     
            BluLimitX[0] = D;           BluLimitX[1] = E;    

            // Set the color limits.
            RedLimitY[0] = White.red;   RedLimitY[1] = Orange.red;
            GrnLimitY[0] = White.green; GrnLimitY[1] = Orange.green;
            BluLimitY[0] = White.blue;  BluLimitY[1] = Orange.blue;
        }
        else
        {
            if( v < F )
            {
                // Set the value limits.
                RedLimitX[0] = E;           RedLimitX[1] = F;       
                GrnLimitX[0] = E;           GrnLimitX[1] = F;        
                BluLimitX[0] = E;           BluLimitX[1] = F;       
        
                // Set the color limits.
                RedLimitY[0] = Orange.red;      RedLimitY[1] = Red.red;
                GrnLimitY[0] = Orange.green;    GrnLimitY[1] = Red.green;
                BluLimitY[0] = Orange.blue;     BluLimitY[1] = Red.blue;
            }
            else
            {
                // Set the value limits.
                RedLimitX[0] = F;           RedLimitX[1] = G;       
                GrnLimitX[0] = F;           GrnLimitX[1] = G;        
                BluLimitX[0] = F;           BluLimitX[1] = G;       
        
                // Set the color limits.
                RedLimitY[0] = Red.red;     RedLimitY[1] = Magenta.red; // Black.red;
                GrnLimitY[0] = Red.green;   GrnLimitY[1] = Magenta.green; // Black.green;
                BluLimitY[0] = Red.blue;    BluLimitY[1] = Magenta.blue; // Black.blue;
            } 
        }           
    }
    
    AColor->red = 
            InterpolateLinear( RedLimitX, RedLimitY, v );
    AColor->green = 
            InterpolateLinear( GrnLimitX, GrnLimitY, v );
    AColor->blue  = 
            InterpolateLinear( BluLimitX, BluLimitY, v );
}

/*------------------------------------------------------------
| MapValueToColor
|-------------------------------------------------------------
|
| PURPOSE: To find the color that cooresponds to a value on
|          a given scale. 
|
| DESCRIPTION: Scales the value to between 0 and 1 and then
| uses the same color map as is used for probability values.
| 
|  MinValue                                      MaxValue
|    0         .4      .47  .5  .53    .6          1.0
|    |----------|-------|---|---|-------|------------|
|   Black      Blu    Cyan  Wt  Orange  Red        Black
|
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.26.96 
------------------------------------------------------------*/
void 
MapValueToColor( f64 v, 
                 f64 AMin, 
                 f64 AMax,
                 RGBColor* AColor )
{
    f64 p;

    p = (v - AMin) / (AMin + AMax);
    
    MapProbabilityToColor( p, AColor );
}

/*------------------------------------------------------------
| OpenGraphicsWindow
|-------------------------------------------------------------
|
| PURPOSE: To open a new color graphics window as the front
|          most, active window. 
|
| DESCRIPTION: Window defaults to slightly less than full
| screen size.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Title string is in 'C' format.
|          Window will be discarded using 
|          'CloseGraphicsWindow'.
|           
| HISTORY: 02.26.96 from 'OpenTextEditWindow'.
|          07.26.96 factored out 'OpenGraphicsWindowAt'.
------------------------------------------------------------*/
WindowPtr
OpenGraphicsWindow( s8* Title )
{
    Rect      ContentRectangle;
    WindowPtr AGraphicsWindow;

    //
    //  Get the screen boundary.
    //
    ContentRectangle = qd.screenBits.bounds;
    
    // Inset the boundary by a 50 pixel margin.
    InsetRect( &ContentRectangle, 50, 50 );
    
    // Allocate the memory for the window record, and
    // make the window invisible.  This is now the current
    // text window.
    AGraphicsWindow = 
        OpenGraphicsWindowAt( Title, &ContentRectangle );
    
    return( AGraphicsWindow );
}

/*------------------------------------------------------------
| OpenGraphicsWindowAt
|-------------------------------------------------------------
|
| PURPOSE: To open a new color graphics window as the front
|          most, active window given a content rectangle. 
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Title string is in 'C' format.
|          Window will be discarded using 
|          'CloseGraphicsWindow'.
|           
| HISTORY: 07.26.97 from 'OpenGraphicsWindow'
------------------------------------------------------------*/
WindowPtr
OpenGraphicsWindowAt( s8* Title, Rect* ContentRectangle )
{
    WindowPtr       AGraphicsWindow;

    c2pstr((char*) Title); // convert to pascal format.

    // Allocate the memory for the window record, and
    // make the window invisible. 

    AGraphicsWindow = 
        NewCWindow( 0,                 // Allocate window record. 
                    ContentRectangle,  // Location of content box. 
                    (u8*) Title,    // The title. 
                    1,              // Visible 
                    documentProc,      // A document window. 
                    (WindowPtr) -1,    // In front of all windows.
                    0,             // Has GoAway box. 
                    0 );               // The refCon field: could
                                       //     put any value there.
    
    // Make this the active port for drawing.                    
    SetPort( AGraphicsWindow );                      
    
    // Set the font for text drawn in window.
//  TextFont(TheTextFont);
    TextSize( CurrentGraphFontHeight ); 
    
    // Restore the format of the title string.
    p2cstr((u8*)Title);        
    
    return( AGraphicsWindow );
}

/*------------------------------------------------------------
| OverlayLineOnGraph
|-------------------------------------------------------------
|
| PURPOSE: To overlay a line on an already drawn graph.
|
| DESCRIPTION: Uses the graph data space window to clip the
| given line, and then draws it in the given color.
|
| Doesn't add the line to the graph data structure:
| just draws the line where it intersects with the
| graph.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.08.96 
------------------------------------------------------------*/
void
OverlayLineOnGraph( LineGraph*   AGraph, 
                    General2DLine* g, 
                    RGBColor*    AColor,
                    f64      LineWidth )
{
    Rectangle2  r;
    TwoPoints   p;
    s32         ptCount;
    
    // Make the clipping rectangle the same as the data space
    // rectangle of the graph.
    r.min.x = AGraph->XMin;
    r.min.y = AGraph->YMin;
    r.max.x = AGraph->XMax;
    r.max.y = AGraph->YMax;
    
    // Find the line segment that falls on the graph.
    ptCount = IntersectLineAndRectangle( g, &r, &p );
    
    // Draw the resulting segment if any.
    if( ptCount == 2 )
    {
        OverlaySegmentOnGraph( AGraph, &p, AColor, LineWidth );
    }
}
 
/*------------------------------------------------------------
| OverlaySegmentOnGraph
|-------------------------------------------------------------
|
| PURPOSE: To overlay a data space line segment on an already 
|          drawn graph.
|
| DESCRIPTION: Converts the line segment to window coordinates
| of the graph and then draws it in the given color.
|
| Doesn't add the line to the graph data structure:
| just draws the line.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.08.96 
------------------------------------------------------------*/
void
OverlaySegmentOnGraph( LineGraph* AGraph, 
                       TwoPoints* p, 
                       RGBColor*  AColor,
                       f64        LineWidth )
{
    s16         h,v; 
    f64     yscale, xscale;
    f64     wxmin, wxmax, wymin, wymax;
    f64     dxmin, dxmax, dymin, dymax;
    f64     x,y;
    
    // Set the line color.
    RGBForeColor( AColor );

    // Set the line width.
    PenSize( (s16) LineWidth, (s16) LineWidth );

    // Get the coord transform data for speed later.
    wxmin = (f64) AGraph->DataArea.left;
    wxmax = (f64) AGraph->DataArea.right;
    wymin = (f64) AGraph->DataArea.top;
    wymax = (f64) AGraph->DataArea.bottom;
    
    dxmin = AGraph->XMin;
    dxmax = AGraph->XMax;
    dymin = AGraph->YMin;
    dymax = AGraph->YMax;

    // Calculate the scaling factors for the data to screen
    // coords.
    yscale =  ( wymax - wymin ) /
              ( dymax - dymin );
          
    xscale =  ( wxmax - wxmin ) /
              ( dxmax - dxmin );

    // Refer to the first point.
    x = p->a.x;
    y = p->a.y;
    
    // Convert to window coordinates.
    h = ((x - dxmin) * xscale) + wxmin;
    v = wymax - ((y - dymin) * yscale);
    
    // Set the starting pen location.
    MoveTo( h, v );
    
    // Refer to the second point.
    x = p->b.x;
    y = p->b.y;
    
    // Convert to window coordinates.
    h = ((x - dxmin) * xscale) + wxmin;
    v = wymax - ((y - dymin) * yscale);
 
    LineTo( h, v );
}

/*------------------------------------------------------------
| SetUpGraphics
|-------------------------------------------------------------
|
| PURPOSE: To set up the program for using graphics.
|
| DESCRIPTION: Only need to call this when the program first
|              starts up.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 02.26.96 
-----------------------------------------------------------*/
void 
SetUpGraphics()
{
    OSErr       error;
    SysEnvRec   theWorld;
    
    // Set the default font parameters.
    CurrentGraphFont = DefaultGraphFont;
    CurrentGraphFontHeight = DefaultGraphFontHeight;
    CurrentGraphFontWidth  = DefaultGraphFontWidth;
    
    //
    //  Test the computer to be sure we can do color.  
    //  If not we would crash, which would be bad.  
    //  If we can¹t run, just beep and exit.
    //

    error = SysEnvirons(1, &theWorld);
    if( theWorld.hasColorQD == false ) 
    {
        SysBeep(50);
        ExitToShell();  /* If no color QD, we must leave. */
    }
    
    // Initialize all the needed managers. Now done by 
    // 'MainSetUp'.
//  InitGraf(&qd.thePort);
//  InitFonts();
//  InitWindows();
//  InitMenus();
//  TEInit();
//  InitDialogs(nil);
//  InitCursor();
    
    // Open the graphics window to be used for all 
    // drawing.
    TheGraphicsWindow = OpenGraphicsWindow( (s8*) "Graph" );
    
    // Keep a copy of the window rectangle for
    // fast access.
    TheGraphicsWindowRect = TheGraphicsWindow->portRect;
    
    
    // Set the default values.
    XPixelsPerMatrixCell = 3;
    YPixelsPerMatrixCell = 3;

    // These color values come from Inside Mac V-69.
    Black.red   = 0x0000; Black.green   = 0x0000; Black.blue   = 0x0000;
    Yellow.red  = 0xfc00; Yellow.green  = 0xf37d; Yellow.blue  = 0x052f;
    Magenta.red = 0xf2d7; Magenta.green = 0x0856; Magenta.blue = 0x84ec;
    Red.red     = 0xdd6b; Red.green     = 0x08c2; Red.blue     = 0x06a2;
    Cyan.red    = 0x0241; Cyan.green    = 0xab54; Cyan.blue    = 0xeaff;
    Green.red   = 0x0000; Green.green   = 0x8000; Green.blue   = 0x11b0;
    Blue.red    = 0x0000; Blue.green    = 0x0000; Blue.blue    = 0xd400;
    White.red   = 0xffff; White.green   = 0xffff; White.blue   = 0xffff;

    // A mixture of red & yellow: 50% of each.
    Orange.red      = 0xecb5; 
    Orange.green    = 0x7e1f;  
    Orange.blue     = 0x05e8; 
}

/*------------------------------------------------------------
| SetUpGraphicsAt
|-------------------------------------------------------------
|
| PURPOSE: To set up the program for using graphics in a
|          window at a given location.
|
| DESCRIPTION: Only need to call this when the program first
|              starts up.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 07.26.97 from 'SetUpGraphics'.
-----------------------------------------------------------*/
void 
SetUpGraphicsAt( Rect* R )
{
    OSErr       error;
    SysEnvRec   theWorld;
    
    // Set the default font parameters.
    CurrentGraphFont = DefaultGraphFont;
    CurrentGraphFontHeight = DefaultGraphFontHeight;
    CurrentGraphFontWidth  = DefaultGraphFontWidth;
    
    //
    //  Test the computer to be sure we can do color.  
    //  If not we would crash, which would be bad.  
    //  If we can¹t run, just beep and exit.
    //

    error = SysEnvirons(1, &theWorld);
    if( theWorld.hasColorQD == false ) 
    {
        SysBeep(50);
        ExitToShell();  /* If no color QD, we must leave. */
    }
    
    // Initialize all the needed managers. Now done by 
    // 'MainSetUp'.
//  InitGraf(&qd.thePort);
//  InitFonts();
//  InitWindows();
//  InitMenus();
//  TEInit();
//  InitDialogs(nil);
//  InitCursor();
    
    // Open the graphics window to be used for all 
    // drawing.
    TheGraphicsWindow = OpenGraphicsWindowAt( (s8*) "Graph", R );
    
    // Keep a copy of the window rectangle for
    // fast access.
    TheGraphicsWindowRect = TheGraphicsWindow->portRect;
    
    
    // Set the default values.
    XPixelsPerMatrixCell = 3;
    YPixelsPerMatrixCell = 3;

    // These color values come from Inside Mac V-69.
    Black.red   = 0x0000; Black.green   = 0x0000; Black.blue   = 0x0000;
    Yellow.red  = 0xfc00; Yellow.green  = 0xf37d; Yellow.blue  = 0x052f;
    Magenta.red = 0xf2d7; Magenta.green = 0x0856; Magenta.blue = 0x84ec;
    Red.red     = 0xdd6b; Red.green     = 0x08c2; Red.blue     = 0x06a2;
    Cyan.red    = 0x0241; Cyan.green    = 0xab54; Cyan.blue    = 0xeaff;
    Green.red   = 0x0000; Green.green   = 0x8000; Green.blue   = 0x11b0;
    Blue.red    = 0x0000; Blue.green    = 0x0000; Blue.blue    = 0xd400;
    White.red   = 0xffff; White.green   = 0xffff; White.blue   = 0xffff;

    // A mixture of red & yellow: 50% of each.
    Orange.red      = 0xecb5; 
    Orange.green    = 0x7e1f;  
    Orange.blue     = 0x05e8; 
}

/*------------------------------------------------------------
| TextRect
|-------------------------------------------------------------
|
| PURPOSE: To calculate the rectangle that bounds the string
|          at the given upper-left point.
|
| DESCRIPTION: Return the extent rectangle relative to a
| point in an image space with point-size units.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: The current font size is valid.
|          Font is mono-spaced, that is, non-proportional 
|          spacing.
|           
| HISTORY: 02.27.96 
|          02.01.97 restricted to mono-spaced fonts.
------------------------------------------------------------*/
Rect*
TextRect( s32 x, s32 y, s8* AString )
{
    static Rect ARect;
    
    s16 w;
    
    // Convert the string to Pascal format.
//  c2pstr( AString );
//  w = StringWidth( (u8*) AString );
    // Convert string back to C format.
//  p2cstr( (u8*) AString );
    w = CountString( AString ) * CurrentGraphFontWidth;
    
    // Calculate the bounding rectangle.
    ARect.top    = y;
    ARect.left   = x;
    ARect.bottom = y + CurrentGraphFontHeight;
    ARect.right  = x + w;
    
    return( &ARect );
}

/*------------------------------------------------------------
| VerticalTextRect
|-------------------------------------------------------------
|
| PURPOSE: To calculate the rectangle that bounds the string
|          at the given upper-left point.
|
| DESCRIPTION:
| 
| The text origin is to the left, top of the text:
|
|         (x,y) +----
|               | A |
|               | A |
|               | A |
|               -----
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 02.27.96 
------------------------------------------------------------*/
Rect*
VerticalTextRect( s32 x, s32 y, s8* AString )
{
    static Rect ARect;
    
    u32 c;
    
    c = CountString( AString );
    
    // Calculate the bounding rectangle.
    ARect.top    = y;
    ARect.left   = x;
    ARect.bottom = y + (CurrentGraphFontHeight*c);
    ARect.right  = x + CurrentGraphFontWidth;
    
    return( &ARect );
}
