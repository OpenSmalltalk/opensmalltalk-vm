#if (DEBUG)

static long getFormatAttribute(NSOpenGLPixelFormat *fmt,
                                   NSOpenGLPixelFormatAttribute attr)
{
  long val;
  [fmt getValues: &val forAttribute: attr forVirtualScreen: 0];
  return val;
}

void printFormatInfo(NSOpenGLPixelFormat *fmt)
{
  printf("GL pixel format:\n");
  // valued
  printf("  RendererID     0x%lx\n", getFormatAttribute(fmt, NSOpenGLPFARendererID ));
  printf("  AuxBuffers     %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAAuxBuffers ));
  printf("  ColorSize      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAColorSize  ));
  printf("  AlphaSize      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAAlphaSize  ));
  printf("  DepthSize      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFADepthSize  ));
  printf("  StencilSize    %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAStencilSize));
  printf("  AccumSize      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAAccumSize  ));
  printf("  ScreenMask     %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAScreenMask ));
  // bool
  printf("  AllRenderers   %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAAllRenderers  ));
  printf("  Stereo         %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAStereo        ));
  printf("  MinimumPolicy  %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAMinimumPolicy ));
  printf("  MaximumPolicy  %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAMaximumPolicy ));
  printf("  OffScreen      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAOffScreen     ));
  printf("  FullScreen     %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAFullScreen    ));
  printf("  SingleRenderer %ld\n",   getFormatAttribute(fmt, NSOpenGLPFASingleRenderer));
  printf("  NoRecovery     %ld\n",   getFormatAttribute(fmt, NSOpenGLPFANoRecovery    ));
  printf("  Accelerated    %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAAccelerated   ));
  printf("  ClosestPolicy  %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAClosestPolicy ));
  printf("  Robust         %ld\n",   getFormatAttribute(fmt, NSOpenGLPFARobust        ));
  printf("  BackingStore   %ld\n",   getFormatAttribute(fmt, NSOpenGLPFABackingStore  ));
  printf("  Window         %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAWindow        ));
  printf("  MultiScreen    %ld\n",   getFormatAttribute(fmt, NSOpenGLPFAMultiScreen   ));
  printf("  Compliant      %ld\n",   getFormatAttribute(fmt, NSOpenGLPFACompliant     ));
}

static long getCtxParam(NSOpenGLContext *ctx, NSOpenGLContextParameter param)
{
  long val;
  [ctx getValues: &val forParameter: param];
  return val;
}

void printContextInfo(NSOpenGLContext *ctx)
{
  long vals[4];
  printf("GL Context Parameters:\n");
  [ctx getValues: vals forParameter: NSOpenGLCPSwapRectangle];
  printf("  SwapRectangle       %ld,%ld %ldx%ld\n", vals[0], vals[1], vals[2], vals[3]);
  printf("  SwapRectangleEnable %ld\n", getCtxParam(ctx, NSOpenGLCPSwapRectangleEnable));
  printf("  RasterizationEnable %ld\n", getCtxParam(ctx, NSOpenGLCPRasterizationEnable));
  printf("  SwapInterval        %ld\n", getCtxParam(ctx, NSOpenGLCPSwapInterval));
  printf("  SurfaceOrder        %ld\n", getCtxParam(ctx, NSOpenGLCPSurfaceOrder));
  printf("  SurfaceOpacity      %ld\n", getCtxParam(ctx, NSOpenGLCPSurfaceOpacity));
  printf("  StateValidation     %ld\n", getCtxParam(ctx, NSOpenGLCPStateValidation));
}

#else /* !DEBUG */

# define printFormatInfo(fmt)
# define printContextInfo(ctx)

#endif
