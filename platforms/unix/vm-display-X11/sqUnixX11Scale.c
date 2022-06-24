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
          XrmDestroyDatabase(db);
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

typedef int px_pos;
typedef unsigned int px_len;
typedef double inch_len;


enum scale_govenor {
  GOV_UNSET = -1,
  center,
  topleft,
  topright,
  bottomleft,
  bottomright,
  primary
};
static enum scale_govenor
_scale_govenor(void)
{
  const char* val = getenv("_SQUEAK_DISPLAY_SCALE_GOVERNOR");
  if (val) {
    if (strcasecmp("center",      val) == 0) return center;
    if (strcasecmp("c",           val) == 0) return center;
    if (strcasecmp("topleft",     val) == 0) return topleft;
    if (strcasecmp("tl",          val) == 0) return topleft;
    if (strcasecmp("topright",    val) == 0) return topright;
    if (strcasecmp("tr",          val) == 0) return topright;
    if (strcasecmp("bottomleft",  val) == 0) return bottomleft;
    if (strcasecmp("bl",          val) == 0) return bottomleft;
    if (strcasecmp("bottomright", val) == 0) return bottomright;
    if (strcasecmp("br",          val) == 0) return bottomright;
    if (strcasecmp("primary",     val) == 0) return primary;
    if (strcasecmp("p",           val) == 0) return primary;
  }
  return center;
}

static bool
should_use_for_scale(px_pos wx, px_pos wy, px_len ww, px_len wh,
                     px_pos ox, px_pos oy, px_len owp, px_len ohp,
                     inch_len owi, inch_len ohi, int outs_count)
{
  if (!sqDefaultScale() || outs_count == 1) {
    /* there's only one out or we don't care about monitor-specifics.
       so any out will do */
    return true;
  }
  static enum scale_govenor gov = GOV_UNSET;
  if (gov == GOV_UNSET) { gov = _scale_govenor(); };
  px_pos
    wcx = wx + ww, wcy = wy + wh,         /* corners */
    ocx = ox + owp, ocy = oy + ohp,
    wmx = wx + (ww/2), wmy = wy + (wh/2); /* center (Middle) */
  switch (gov) {
  case center:
    return wmx >= ox && wmx <= ocx && wmy >= oy && wmy <= ocy;
  case topleft:
    return wx  >= ox && wx  <= ocx && wy  >= oy && wy  <= ocy;
  case topright:
    return wcx >= ox && wcx <= ocx && wy  >= oy && wy  <= ocy;
  case bottomleft:
    return wx  >= ox && wx  <= ocx && wcy >= oy && wcy <= ocy;
  case bottomright:
    return wcx >= ox && wcx <= ocx && wcy >= oy && wcy <= ocy;
  case primary: /* fallthrough */
  default: return true;
  }
  return true; /* never reached */
}


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
  px_pos win_x, win_y;
  px_len win_w_px, win_h_px;
  { /* find position and extent of our window */
    Window root, child;
    px_len _; /* not interesting */
    px_pos wx,wy,rx,ry;
    /* where are we relative to our root */
    XGetGeometry(stDisplay, stWindow, &root,
                 &wx, &wy, &win_w_px, &win_h_px, &_, &_);
    /* where is our root */
    XTranslateCoordinates(stDisplay, stWindow, root,
                          0, 0, &rx, &ry, &child);
    /* where are we absolute */
    win_x = rx - wx;
    win_y = ry - wy;
  }

  XRRScreenResources* res =
    Xrandr_XRRGetScreenResourcesCurrent(stDisplay, stWindow);
  if (!res || res->noutput == 0) {
    if (res) {
      Xrandr_XRRFreeScreenResources(res);
    }

    res = Xrandr_XRRGetScreenResources(stDisplay, stParent);
  }
  if (res) {
    for (int output = 0; output < res->noutput; output++) {
      XRROutputInfo* output_info =
        Xrandr_XRRGetOutputInfo(stDisplay, res, res->outputs[output]);
      if (!output_info || !output_info->crtc ||
          output_info->connection == RR_Disconnected) {
        Xrandr_XRRFreeOutputInfo(output_info);
        continue;
      }

      inch_len out_w_inch = (double)output_info->mm_width / 25.4;
      inch_len out_h_inch = (double)output_info->mm_height / 25.4;
      RRCrtc output_crtc = output_info->crtc;
      Xrandr_XRRFreeOutputInfo(output_info);

      XRRCrtcInfo *crtc =
        Xrandr_XRRGetCrtcInfo(stDisplay, res, output_crtc);
      if (!crtc) {
        continue;
      }

      px_pos out_x = crtc->x;
      px_pos out_y = crtc->y;
      px_len out_w_px = crtc->width;
      px_len out_h_px = crtc->height;
      Xrandr_XRRFreeCrtcInfo(crtc);

      /*
       * Use the first output if _not_ in per-monitor mode, otherwise
       * Look whether we are on _this_ output
       */
      bool use_this =
        should_use_for_scale(win_x, win_y, win_w_px, win_h_px,
                             out_x, out_y, out_w_px, out_h_px,
                             out_w_inch, out_h_inch, res->noutput);
      if (use_this) {
        DPRINTF(("Determining factor from px: %dx%d, inch: %fx%f\n",
                 out_w_px, out_h_px, out_w_inch, out_h_inch));
        scale = sqScaleFromPhysical(out_w_px, out_h_px,
                                    out_w_inch, out_h_inch);
        break;
      }
    }
  }
  Xrandr_XRRFreeScreenResources(res);
  return scale;
}
