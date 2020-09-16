/****************************************************************************
*   PROJECT: X11 scale factor helpers (X11/fbdev/..)
*   FILE:    sqUnixX11Scale.c
*   CONTENT: Helper to find scale factor on X11
*
*   AUTHORS: Tobias Pape (topa)
*               Hasso Plattner Institute, Potsdam, Germany
*
*****************************************************************************/

#include <stdbool.h>
#include <dlfcn.h>

#include "debug.h"
#include <X11/Xresource.h>

#include <X11/extensions/Xrandr.h> /* at least at compiletime */

/*
 *
 * We want to avoid linking Xrandr in case it's not installed.
 * This here would be the only dependency, so rather load it
 * dynamically.
 *
 */

#if !defined(__OpenBSD__)
#  define DL_FLAGS (RTLD_NOW | RTLD_GLOBAL | RTLD_NODELETE)
#else
#  define DL_FLAGS (RTLD_NOW | RTLD_GLOBAL)
#endif

void* _use_lib(const char* name)
{
  /* 0. */
  if (name == NULL) {
    return  dlopen(name, DL_FLAGS);
    DPRINTF(("Found self\n"));
  }
  void* handle = NULL;
  /* 2. */
  if ((handle = dlopen(name, DL_FLAGS)) != NULL) {
    DPRINTF(("Found %s proper\n", name));
    return handle;
  }
  // any?
  return NULL;
}

#define FOUND_SYM(s,n,h)  do {                          \
    if ((s = dlsym(h, n))) {                            \
      DPRINTF(("Found symbol %s in " #h "\n", n));      \
      return s;                                         \
    }                                                   \
  } while (0)
#define FIND_SYM(sym, name, where, dlname) do {                 \
    if (!dlhandle_ ## where) {                                  \
      DPRINTF(("Loading %s\n",(dlname)?(dlname):"self"));       \
      dlhandle_ ## where = _use_lib(dlname);                    \
    }                                                           \
    if (dlhandle_ ## where) {                                   \
      FOUND_SYM(sym, name, dlhandle_ ## where);                 \
    }                                                           \
  } while (0)


static void* dlhandle_self = NULL;
static void* dlhandle_Xrandr = NULL;

static inline void* _find_Xrandr(const char* name)
{
  void* sym = NULL;
  FOUND_SYM(sym, name, RTLD_DEFAULT);
  FIND_SYM(sym, name, self, NULL);
  FIND_SYM(sym, name, Xrandr, "libXrandr.so");
  DPRINTF(("Cannot find %sn", name));
  return sym;
}

#define _S(_L, n) _L ## _ ## n
#define USING_SYM(_L, ret, name, ...)                   \
  static ret (*_S(_L, name))(__VA_ARGS__) = NULL;

#define LOAD_SYM(_L, excp, ret, name, ...) do {                         \
    if (!_S( _L , name)) {                                              \
      _S(_L, name) = (ret (*)(__VA_ARGS__)) _find_Xrandr(#name);        \
    }                                                                   \
    if (!_S(_L, name)) {                                                \
      excp;                                                             \
    }                                                                   \
  } while (0)                                                           \

#define LOADING_SYM(_L, ret, name, ...)                 \
  LOAD_SYM(_L, return false, ret, name, __VA_ARGS__)


bool scale_Xftdpi_usable(void)
{
  /*
   * Xft.dpi is per se not physical and also not per-monitor.
   */
  if (sqPreferPhysicalScale() || sqPerMonitorScale()) {
    return false;
  }
  char* rms = XResourceManagerString(stDisplay);
  if (rms) {
    XrmDatabase db = XrmGetStringDatabase(rms);
    if (db) {
      XrmValue value;
      char* type = NULL;
      if (XrmGetResource(db, "Xft.dpi", "Xft.Dpi", &type, &value)) {
        if (type && strcmp(type, "String") == 0) {
          DPRINTF(("Displayscale: present Xft.dpi\n"));
          return true;
        }
      }
    }
    XrmDestroyDatabase(db);
  }
  DPRINTF(("Displayscale: no    Xft.dpi\n"));
  return false;
}

double scale_Xftdpi(void)
{
  const double base_dpi = 96.0;
  double scale = sqDefaultScale();
  XrmInitialize();
  char* rms = XResourceManagerString(stDisplay);
  if (rms) {
    XrmDatabase db = XrmGetStringDatabase(rms);
    if (db) {
      XrmValue value;
      char* type = NULL;
      if (XrmGetResource(db, "Xft.dpi", "Xft.Dpi", &type, &value)) {
        if (type && strcmp(type, "String") == 0) {
          DPRINTF(("Displayscale: found Xft.dpi: %s\n", value.addr));
          double l_dpi = strtod(value.addr, NULL);
          if (isnormal(l_dpi) && l_dpi > 0) {
            scale = l_dpi / base_dpi;
          }
        } else {
          DPRINTF(("Displayscale: no    Xft.dpi\n"));
        }
      } else {
        DPRINTF(("Displayscale: no    Xft.dpi\n"));
      }
    }
    XrmDestroyDatabase(db);
  }
  return scale;
}



USING_SYM(Xrandr, XRRScreenResources *, XRRGetScreenResources, Display *dpy, Window window)
USING_SYM(Xrandr, void, XRRFreeScreenResources, XRRScreenResources *resources)
USING_SYM(Xrandr, XRROutputInfo * , XRRGetOutputInfo, Display *dpy, XRRScreenResources *resources, RROutput output)
USING_SYM(Xrandr, XRRCrtcInfo *, XRRGetCrtcInfo, Display *dpy, XRRScreenResources *resources, RRCrtc crtc)
USING_SYM(Xrandr, void, XRRFreeCrtcInfo, XRRCrtcInfo *crtcInfo)
USING_SYM(Xrandr, XRRScreenResources *, XRRGetScreenResourcesCurrent, Display *dpy, Window window)
USING_SYM(Xrandr, void, XRRFreeOutputInfo, XRROutputInfo *outputInfo)


bool scale_xrandr_usable(void)
{
  LOADING_SYM(Xrandr, XRRScreenResources *, XRRGetScreenResources, Display *dpy, Window window);
  LOADING_SYM(Xrandr, void, XRRFreeScreenResources, XRRScreenResources *resources);
  LOADING_SYM(Xrandr, XRROutputInfo * , XRRGetOutputInfo, Display *dpy, XRRScreenResources *resources, RROutput output);
  LOADING_SYM(Xrandr, XRRCrtcInfo *, XRRGetCrtcInfo, Display *dpy, XRRScreenResources *resources, RRCrtc crtc);
  LOADING_SYM(Xrandr, void, XRRFreeCrtcInfo, XRRCrtcInfo *crtcInfo);
  LOADING_SYM(Xrandr, XRRScreenResources *, XRRGetScreenResourcesCurrent, Display *dpy, Window window);
  LOADING_SYM(Xrandr, void, XRRFreeOutputInfo, XRROutputInfo *outputInfo);
  return true;
}
double scale_xrandr(void)
{
  double scale = sqDefaultScale();
  int x, y;
  { /* find position of our window */
    Window root, child;
    unsigned int _; /* not interesting */
    int wx,wy,rx,ry;
    /* where are we relative to our root */
    XGetGeometry(stDisplay, stWindow, &root, &wx, &wy, &_, &_, &_, &_);
    /* where is our root */
    XTranslateCoordinates(stDisplay, stWindow, root, 0, 0, &rx, &ry, &child);
    /* where are we absolute */
    x = rx-wx;
    y = ry-wy;
  }
  
  XRRScreenResources* res = Xrandr_XRRGetScreenResourcesCurrent(stDisplay, stWindow);
  if (!res || res->noutput == 0) {
    if (res) {
      Xrandr_XRRFreeScreenResources(res);
    }

    res = Xrandr_XRRGetScreenResources(stDisplay, stParent);
  }
  if (res) {
    for (int output = 0; output < res->noutput; output++) {
      XRROutputInfo* output_info = Xrandr_XRRGetOutputInfo(stDisplay, res, res->outputs[output]);
      if (!output_info || !output_info->crtc ||
          output_info->connection == RR_Disconnected) {
        Xrandr_XRRFreeOutputInfo(output_info);
        continue;
      }

      double x_inch = (double)output_info->mm_width / 25.4;
      double y_inch = (double)output_info->mm_height / 25.4;
      RRCrtc output_crtc = output_info->crtc;
      Xrandr_XRRFreeOutputInfo(output_info);

      XRRCrtcInfo *crtc = Xrandr_XRRGetCrtcInfo(stDisplay, res, output_crtc);
      if (!crtc) {
        continue;
      }
      /*
       * Use the first output if _not_ in per-monitor mode, otherwise
       * Look whether we are on _this_ output 
       */
      if (!sqPerMonitorScale() ||
          (x >= crtc->x && x <= (crtc->x + crtc->width) &&
           y >= crtc->y && y <= (crtc->y + crtc->height))) {

        unsigned int x_px = crtc->width;
        unsigned int y_px = crtc->height;
        Xrandr_XRRFreeCrtcInfo(crtc);
        DPRINTF(("Determining factor from px: %dx%d, inch: %fx%f\n",
                 x_px, y_px, x_inch, y_inch));

        scale = sqScaleFromPhysical(x_px, y_px, x_inch, y_inch);
        break;
      }
    }
  }
  Xrandr_XRRFreeScreenResources(res);
  return scale;
}

