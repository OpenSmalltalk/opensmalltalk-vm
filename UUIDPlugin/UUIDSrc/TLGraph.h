/*------------------------------------------------------------
| TLGraph.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to graphics functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 02.26.96 
------------------------------------------------------------*/

#include <Types.h>
#include <Memory.h>
#include <Quickdraw.h>

#ifndef _GRAPH_H_
#define _GRAPH_H_

// Defaults
#if ( __MWERKS__ >= 0x2000 ) // Release 3
#define DefaultGraphFont            kFontIDMonaco
#else
#define DefaultGraphFont            monaco
#endif

#define DefaultGraphFontWidth       6  // monaco  
#define DefaultGraphFontHeight      9  // monaco 
#define DefaultTextTopToBaseLine   11  // monaco 

// TextLine Y values:
#define Line1   5
#define Line2   (Line1 + CurrentGraphFontHeight + 2)
#define Line3   (Line2 + CurrentGraphFontHeight + 2)
#define Line4   (Line3 + CurrentGraphFontHeight + 2)

// To organize and integrate parameters of a font instance.
typedef struct
{
    s8*     FontName;  // Name string of font, eg. "Monaco".
    u32     FontID;    // ID number of the font, eg. 'monaco'.
    u32     FontWidth; // How many points wide the font is.
    u32     FontHeight;// How many points tall the font is.
} GraphFont;



// This organizes a line graph:
typedef struct
{
// Add window reference later.
    s8          Title[128];
    Rect        FullArea;  // Extent of the entire graph on the window.
    Rect        DataArea;  // Extent of the data area on the window.
    f64         XMin;      // Extent of the graph in data space.
    f64         YMin;      //
    f64         XMax;      //
    f64         YMax;      //
//  u32       IsVisible; // Is the line graph currently
                         // visible.
    u32         IsBackground;    // Whether background should be drawn.
    u32         IsBorder;        // Whether border should be drawn.
    u32         IsDataBorder;    // Whether border should be drawn 
                               // around the data area.
    u32         IsDataSpaceBorder; // Whether part of data space
                               // around the data points should be 
                               // included on the graph.
    RGBColor    FillColor;       // The color used for the background.
    RGBColor    BorderColor;     // The color used for the border.
    f64         BorderLineWidth; // The width of the border line.
    u32         IsXAxis;           // Whether x axis should be drawn.
    u32         IsYAxis;           // Whether y axis should be drawn.
    u32         IsXGrid;         // Whether an x axis grid should
                               // be drawn.
    u32         IsYGrid;         // Whether a y axis grid should
                               // be drawn.
    u32         IsXTickMarks;    // Whether x tick marks should 
                               // be drawn where grid would go.
    u32         IsYTickMarks;    // Whether y tick marks should 
                               // be drawn where grid would go.
    u32         IsXTickLabels;   // Whether numbers should label
                               // the X tick marks.
    u32         IsYTickLabels;   // Whether numbers should label
                               // the Y tick marks.
    s8          XTickFormat[32]; // The format string to be used
                               // X tick labels.
    s8          YTickFormat[32]; // The format string to be used
                               // Y tick labels.
    f64         GridLineWidth;   // The width of the grid line.
    f64         XGridDelta;      // Space between x axis grid.
    f64         YGridDelta;      // Space between y axis grid.
    s8          XAxisLabel[128]; // The dimension of the x axis.
    s8          YAxisLabel[128]; // The dimension of the y axis.
    List*       Data;              // Each item in the list refers
                               // to a dynamically allocated 
                               // 'DataSeries' record.
                               //
    List*     Labels;          // List of 'TextLabel' records to
                               // to be superimposed on the graph.
} LineGraph;

// This organizes a data series and drawing format used on a graph:
typedef struct
{ 
    s8          Name[128];     // Name of the data series.
    Vector*     Data;          // The data points.
    s16*        WinPt;         // Where the window (h,v) points are 
                               // stored.
                               // This is dynamically allocated.
    u32         IsConnected;   // Whether points should be connected.
    u32         IsPointsDrawn; // Whether points should be drawn.
    RGBColor    LineColor;     // The color used to draw the data.
    f64         LineWidth;     // How wide the line is when drawn.
    f64         PointRadius;   // One half the diameter of the point.
    LineGraph*  Graph;         // Reference to the graph where this
                               // series is drawn.
} DataSeries;

// Alignment codes for rectangles: where the movable rectangle
// is placed relative to the fixed alignment rectangle.
//
//          AlignmentRect
//         --------------------------------------------------------
//         | Left, Top         CenterX,Top             Right, Top |
//         |                                                      |
//         |                                                      |
//         | Left, CenterY     CenterX,CenterY     Right, CenterY |
//         |                                                      |
//         |                                                      |
//         | Left, Bottom      CenterX,Bottom       Right, Bottom |
//         --------------------------------------------------------
//
// Alignment codes are encoded as a series of bits:
//
//       5 4 3 2 1 0
//       0 0 0 0 0 0
//        \ \ \ \ \ \_ Left 
//         \ \ \ \ \__ CenterX
//          \ \ \ \___ Right
//           \ \ \____ Top
//            \ \_____ CenterY
//             \______ Bottom

#define AlignNothing      0
#define AlignLeft         BitOfByte[0]
#define AlignCenterX      BitOfByte[1]
#define AlignRight        BitOfByte[2]
#define AlignTop          BitOfByte[3]
#define AlignCenterY      BitOfByte[4]
#define AlignBottom       BitOfByte[5]
#define AlignTopLeft      (AlignTop | AlignLeft)
#define AlignTopCenter    (AlignTop | AlignCenterX)
#define AlignTopRight     (AlignTop | AlignRight)
#define AlignCenterLeft   (AlignCenterY | AlignLeft)
#define AlignCenterCenter (AlignCenterY | AlignCenterX)
#define AlignCenterRight  (AlignCenterY | AlignRight)
#define AlignBottomLeft   (AlignBottom  | AlignLeft)
#define AlignBottomCenter (AlignBottom  | AlignCenterX)
#define AlignBottomRight  (AlignBottom  | AlignRight)

//
//
//             Origin pixel: defines placement
//            /
//     --- --/----------  ---
//      |  |+...@......|   |
//      H  |...@.@.....|   |
//      e  |..@...@....|  TopToBaseline
//      i  |.@@@@@@@...|   |
//      g  |@.......@..|   |
//      h --...........---------- Baseline
//      t  |..........*|<-- Last pixel: defines extent
//     --- ------------- 
//         |<--Width-->| \_ TextExtent rectangle
//
//
// If an border box is drawn around a block of text it is placed
// so that there is an empty row of pixels between the border
// and the text extent on all sides except the right side, like this:
//
//        @@@@@@@@@@@@@@ 
//        @            @
//        @ +...@......@
//        @ ...@.@.....@ 
//        @ ..@...@....@  
//        @ .@@@@@@@...@
//        @ @.......@..@ 
//        @ ...........@ 
//        @ ..........*@ 
//        @            @
//        @@@@@@@@@@@@@@ 
//          

// This integrates all information about putting a text label
// on a graph.
typedef struct
{
    s8*         Text;           // The text of the label. Dynamic.
                                //
    GraphFont*  Font;           // Reference to the font instance to be used.
                                // If this is zero then the current graph font
                                // is used.
                                //
    RGBColor    TextColor;      // Foreground color for the text.
                                //
    RGBColor    BackgroundColor;// Background fill color, if any.
                                //
    RGBColor    BorderColor;    // The color to use if drawing a box around
                                // the text.
                                //
    u32         AlignmentCode;  // Alignment code for the text. See above.
                                //
    u32         IsAlignToBox;   // 1 if the text extent should be aligned
                                // to the alignment box according to the
                                // 'AlignmentCode'.
                                // 
    u32         IsAlignToPoint; // 1 if the label should be aligned 
                                // relative to the data point.
                                //
    u32         IsBackground;   // 1 if a background color should be
                                // used to fill the text box.
                                // 
    u32         IsBorder;       // 1 if a border should be drawn 
                                // around the text.
                                //
    u32         IsDataPointLabel; 
                                // 1 if the label refers to a data point.
                                //
    u32         IsLineToDataPoint;
                                // 1 if a line should be drawn from the
                                // label to the data point.  Uses 
                                // 'BorderLineWidth'.
                                //
    Rect        BorderExtent;   // The rectangle used to draw an outline 
                                // around the text. Render space.
                                //
    f64         LineWidth;      // The width of the border and radial lines
                                // in points.
                                //
    Rect        TextExtent;     // The pixel extent of the text in render
                                // space.  The extent is defined by the
                                // first and last pixel.  This may be 
                                // computed if alignment is enabled by
                                // setting 'IsAlignToBox' or 
                                // 'IsAlignToPoint' to 1.
                                // 
    Rect        AlignmentBox;   // The rectangle within which alignment is
                                // done. Render space.
                                //
    f64         DataX;          // Data point X of the label.
                                //
    f64         DataY;          // Data point X of the label. 
                                //
    s32         RadiusFromDataPoint; 
                                // How far away the center of the label is 
                                // to be placed from the data point, in pixels.
                                //
    LineGraph*  Graph;          // Reference to the graph where the
                                // label is drawn.
} TextLabel;



// The current graphics window.
extern WindowPtr    TheGraphicsWindow;

// The rectangle of the current graphics window.
extern Rect         TheGraphicsWindowRect;

// Fonts
extern GraphFont Monaco9;

// The current graph font parameters.
extern s32  CurrentGraphFont;   // ID number of of the current 
                                // graph font, eg. 'monaco'. 
                                //
extern s32  CurrentGraphFontHeight; // The height in points (1/72nd") 
                                // of the current graph font.
                                //
extern s32  CurrentGraphFontWidth; // The width in points (1/72nd") 
                                // of the current graph font.
                                //

// Colors:
extern RGBColor Black;
extern RGBColor Yellow;
extern RGBColor Magenta;
extern RGBColor Red;
extern RGBColor Orange;
extern RGBColor Cyan;
extern RGBColor Green;
extern RGBColor Blue;
extern RGBColor White;

extern Rect DefaultGraphRect;

void        AddLabelToGraph( LineGraph*, TextLabel* );
DataSeries* AddLinesToGraph( LineGraph*, Vector*, RGBColor* );
DataSeries* AddPointsToGraph( LineGraph*, Vector*, RGBColor* );
void        AlignRectToRect( Rect*, Rect*, s32 );
void        AutoScaleLineGraph( LineGraph* );
void        AutoScaleLineGraphSquare( LineGraph* );
Rect*       CalculateTextExtent( s32, s32, GraphFont*, s8* );
void        ClearGraphicsWindow();
void        ClearTextLine( s32, s32);
void        CloseGraphicsWindow( WindowPtr );
void        DeleteGraph( LineGraph* );
void        DrawDataSeries( DataSeries* );
void        DrawFilledRectangle( Rect*, RGBColor* );
void        DrawGraph( LineGraph* );
void        DrawGraphTextLabels( LineGraph* );
void        DrawLineGraphDataArea( LineGraph* );
void        DrawLineGraphDataSeries( LineGraph* );
void        DrawMatrix( Matrix*, s8*, s32, s32, s32, s32 );
void        DrawPoints( Vector*, Rect*, RGBColor* );
void        DrawProbabilityMatrix( Matrix*, s8*, s32, s32, s32, s32 );
void        DrawProbabilityMatrix2( Matrix*, s8*, s32, s32, s32, s32 );
void        DrawProbabilityMatrix3( Matrix*, s8*, s32, s32, s32, s32 );
void        DrawRectangle( Rect*, RGBColor* );
void        DrawStringAt( s32, s32, s8*, ... );
void        DrawStringCenteredAt( s32, s32, s8*, ... );
void        DrawStringOnLine( s32, s32, s8*, ... );
void        DrawTextLabel( TextLabel* );
void        DrawVerticalStringCenteredAt( s32, s32, s8*, ... );
void        EraseDataSeries( DataSeries* );
void        InitializeColorConstants();
DataSeries* MakeDataSeries( LineGraph*, s8*, Vector*, RGBColor* );
LineGraph*  MakeGraph( s8*, Rect* );
TextLabel*  MakeTextLabel( f64, f64, s8* );
void        MakeTint( RGBColor*, RGBColor*, f64 );
void        MapProbabilityToColor( f64, RGBColor* );
void        MapProbabilityToColor2( f64, RGBColor* );
void        MapProbabilityToColor3( f64, RGBColor* );
void        MapValueToColor( f64, f64, f64, RGBColor* );
WindowPtr   OpenGraphicsWindow( s8* );
WindowPtr   OpenGraphicsWindowAt( s8*, Rect* );
void        OverlayLineOnGraph( LineGraph*, General2DLine*, RGBColor*, f64 );
void        OverlaySegmentOnGraph( LineGraph*, TwoPoints*, RGBColor*, f64 );
void        SetUpGraphics();
void        SetUpGraphicsAt( Rect* );
Rect*       TextRect( s32, s32, s8* );
Rect*       VerticalTextRect( s32, s32, s8* );

#endif // _GRAPH_H_
