/* sample memory surface plugin implementation */
#include <malloc.h>
#include "sqVirtualMachine.h"
#include "ExampleSurfacePlugin.h"
#include "../SurfacePlugin/SurfacePlugin.h"

typedef struct memSurface {
  int width, height, depth, stride;
  void *bits;
} memSurface;

/* entry points for surface manager; looked up at startup */
static fn_ioRegisterSurface registerSurface = 0;
static fn_ioUnregisterSurface unregisterSurface = 0;
static fn_ioFindSurface findSurface = 0;

extern struct VirtualMachine *interpreterProxy;

/******************* Surface manager entry points *******************/
static int memGetSurfaceFormat(sqIntptr_t handle, int *w, int *h, int *d, int *msbFlag) {
  memSurface *ms = (memSurface *) handle;
  *w = ms->width;
  *h = ms->height;
  *d = ms->depth;
  *msbFlag = 0; /* should really depend on platform */
  return 1;
}

static sqIntptr_t memLock(sqIntptr_t handle, int *stride, int x, int y, int w, int h){
  /* Locking can be safely ignored for memory surfaces but we need to fill in 
     the stride and return the bits */
  memSurface *ms = (memSurface *) handle;
  *stride = ms->stride;
  return (sqIntptr_t)ms->bits;
}

static int memUnlock(sqIntptr_t handle, int x, int y, int w, int h){
  return 1; /* ignored */
}

static int memShow(sqIntptr_t handle, int x, int y, int w, int h) {
  /* unsupported */
  return 0;
}

static sqSurfaceDispatch memSurfaceDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) memGetSurfaceFormat,
  (fn_lockSurface) memLock,
  (fn_unlockSurface) memUnlock,
  (fn_showSurface) memShow
};

/******************* primitive entry points *******************/

int memCreateSurfaceWidthHeightDepth(int w, int h, int d) {
  memSurface *ms;
  int id;
  /* since I'm lazy I'll only deal with d >= 8 */
  if(d < 8) return -1; /* indicates failure */
  /* create the memory surface */
  ms = calloc(1, sizeof(memSurface));
  ms->width = w;
  ms->height = h;
  ms->depth = d;
  ms->stride = w * (d >> 3);
  ms->bits = calloc(ms->stride, ms->height);
  /* register memory surface */
  if(!(*registerSurface)((sqIntptr_t)ms, &memSurfaceDispatch, &id)) {
    /* registration failed; bail */
    free(ms->bits);
    free(ms);
    return -1;
  }
  return id;
}

int memDestroySurface(int id) {
  memSurface *ms;
  if(!(*findSurface)(id, &memSurfaceDispatch, (sqIntptr_t*) &ms)) return 0;
  (*unregisterSurface)(id);
  free(ms->bits);
  free(ms);
  return 1;
}

int memGetSurfaceWidth(int id) {
  memSurface *ms;
  if(!(*findSurface)(id, &memSurfaceDispatch, (sqIntptr_t*) &ms)) return 0;
  return ms->width;
}

int memGetSurfaceHeight(int id) {
  memSurface *ms;
  if(!(*findSurface)(id, &memSurfaceDispatch, (sqIntptr_t*) &ms)) return 0;
  return ms->height;
}

int memGetSurfaceDepth(int id) {
  memSurface *ms;
  if(!(*findSurface)(id, &memSurfaceDispatch, (sqIntptr_t*) &ms)) return 0;
  return ms->depth;
}

sqIntptr_t memGetSurfaceBits(int id) {
  memSurface *ms;
  if(!(*findSurface)(id, &memSurfaceDispatch, (sqIntptr_t*) &ms)) return 0;
  return (sqIntptr_t) ms->bits;
}

int memInitialize(void) {
  /* look up the required entry points */
  registerSurface = (fn_ioRegisterSurface) 
    interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
  unregisterSurface = (fn_ioUnregisterSurface)
    interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
  findSurface = (fn_ioFindSurface)
    interpreterProxy->ioLoadFunctionFrom("ioFindSurface","SurfacePlugin");

  /* if any of the above fail we won't load the plugin */
  if(!registerSurface) return 0;
  if(!unregisterSurface) return 0;
  if(!findSurface) return 0;
  return 1;
}

