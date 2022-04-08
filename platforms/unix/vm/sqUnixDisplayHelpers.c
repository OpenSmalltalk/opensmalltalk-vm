/****************************************************************************
*   PROJECT: Unix Display helpers (X11/fbdev/..)
*   FILE:    sqUnixDisplayHelpers.c
*   CONTENT: Miscellaneous helpers for display handling
*
*   AUTHORS: Tobias Pape (topa)
*               Hasso Plattner Institute, Potsdam, Germany
*
*****************************************************************************/

/* If one really wants debugging output use e.g. -DDEBUG=2 */
#if DEBUG <= 1
# undef DEBUG
# define DEBUG 0
#endif

#include "sq.h"
#include "sqUnixDisplayHelpers.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include "debug.h"

/**********************************************************************/
/**********************************************************************/
/*************    Display Scale Factor Helpers    *********************/
/**********************************************************************/
/**********************************************************************/



#pragma mark Historical sidenote

/**********************************************************************
 *
 * On Scale Factors
 *      Beginning in 2013, the pixel started to lose its meaning. With
 *      the introduction of very high density displays on a
 *      comparatively small form factor, "High-DPI" displays reached
 *      print-adjacent resolutions.
 *        Embracing the "Retina" display, Apple urged developers to
 *      abandon the pixel an think in abstact points. Technically, the
 *      Darwin-based OSes now use a **Backing Scale Factor** between
 *      what programmers write and what actual pixel sizes are used.
 *      Coincidentally, the most used are `1.0` for the majority of
 *      "non-Retina" Displays, and `2.0` for Retina displays.
 *      Meanwhile, these Factors can differ between multiple Displays
 *      attached to the same machine. 
 *        Looking bewildered, Windows long time had the capabilty to
 *      "scale" its whole UI in percent, often out of accessibility
 *      reasons. However, only some time after Apple popularized their
 *      "Retina" displays, Windows gained the capability of specifying
 *      individual scales for separate monitors.
 *
 *        Here, we are on Unix and Linux, and there's nothing of that
 *      sort. What we have is different sources of physical facts
 *      about monitors: height, width, resolution. However, different
 *      means of obtaining this information effect different
 *      results[1]. One common approach is to "leave it to the user",
 *      that is, maybe provide means to change the zoom of a
 *      program/UI in its preferences, and if not, tough. Another
 *      taken by the main competing GUI frameworks (GTK, Qt, etc.) is
 *      environment variables that prescribe the scale to wich
 *      applications using these frameworks will adhere. If youre not
 *      using one of these, good luck. If you're not using X11, go
 *      figure. 
 *         And none of them allow separate scale factors for different
 *      montiors. 
 *         We will have to be inventive, again. 
 *
 *
 * On DPI
 *      Without copying too much from Wikipedia, DPI (dots per inch)
 *      is the wrong metric with a wrong name and does not do what we
 *      want[2]. That said, sometimes that's all we have to start
 *      about our journey. Consequently, we have to be aware of a few
 *      ... things (see Wikipedia:DPI)
 *       - The go-to DPI has for a long time been 96 DPI in the
 *         Microsoft world, for several historical reasons. This is
 *         probably the most widely used understanding of
 *         standard-definition pixel density, irresepective of
 *         physical sizes.
 *           Incidentally, these are "nearly" 100 DPI.
 *       - In Macintosh/Apple world, the default density is 72 DPI,
 *         stemming from print publishing, where a printing _point_ is
 *         1/72 of an inch[3]. That's also why their newer Retina
 *         displays typically report 144 DPI; the scale factor is 2.
 *         One not so incidental fact is that a 10 point font, where
 *         the M is to be 10 point wide, has a pixel size of 10 pixel.
 *           We have a nice 10 Pixel per Em (PPEm).
 *       - When dealing with reported "physical" DPI, converting them
 *         to kind-of "logical" DPI seems to be the least-bad of all
 *         variants...
 *
 *
 * Footnotes:
 * [1]  And often bewilderment. While yours truly is wrinting this,
 *      the majority of software running thinks that the screen these
 *      charcters appear on the first time has a density of 96 DPI.
 *      Physically, the monitor (Dell Ultrasharp UP2716D) has actually
 *      a ~60cm by 34cm visible screen at 2560x1440 pixel. That
 *      amounts to ~108 dpi. This can be confusing at best.
 * [2]  There are no dots per se, these come from printing, but pixels,
 *      (-> pixel per inch/PPI), and who's using imperial measurements
 *      (-> dots/pixel per cm)? The "pitch", given in micormeter or
 *      fractional part of milimeters, are increasingly provided by
 *      manufacturers; Dell gives the "pitch" for the mointor in [1]
 *      as `0.233mm`.
 * [3]  "Well, actually". We go with 72 here, that's the "desktop
 *      publishing point." Printer points (or Johnson/American points)
 *      are 1/72.29 of an inch. TeX uses 1/72.27. Olden time Europe
 *      had their own interpretation, too: French Didot points werre
 *      1/67.56 inch, German Didot points were 1/67.54 inch (not that
 *      the American inch mattered there; they had their own inches,
 *      and the French ones derive from 1/72 french inch; and, in
 *      fact, German Berhold points are defined as 2660 points per
 *      meter).
 *
 **********************************************************************/
static const double default_scale = 1.0;
static const double base_dpi = 96.0;

double
sqDefaultScale(void)
{
  return default_scale;
}

/*
 * Environment variable helpers.
 * Return true iff 
 *  - variable is set AND NOT Any of
 *    false,False,FALSE,NO,No,no,n,0
 *
 */
static bool
is_env_true(const char* const env_var)
{
  char* var_value = getenv(env_var);
  DPRINTF(("Displayscale: Var %s ", env_var));
  if (var_value) {
    DPRINTF(("is %s\n", var_value));
    if (strcasecmp("false", var_value) == 0) return false;
    if (strcasecmp("f",     var_value) == 0) return false;
    if (strcasecmp("no",    var_value) == 0) return false;
    if (strcasecmp("n",     var_value) == 0) return false;
    if (strcasecmp("0",     var_value) == 0) return false;
    return true;
  }
  DPRINTF(("is not set\n"));
  return false;
}

static bool
use_per_monitor(void)
{
  return is_env_true(DISPLAY_PER_MONITOR_SCALE);
}


static bool
use_physical(void)
{
  return is_env_true(DISPLAY_PREFER_PHYSICAL_SCALE);
}


/*
 * True when users want per-monitor scale. 
 * Note: the same monitor may report different factors with or without
 * this setting.
 */
bool
sqPerMonitorScale(void)
{
  static bool permonitor_set = false;
  static bool permonitor = false;
  if (!permonitor_set) {
    permonitor_set = true;
    permonitor = use_per_monitor();
  }
  return permonitor;
}

/*
 * True when users prefer physical scale factors.
 */
bool
sqPreferPhysicalScale(void)
{
  static bool physical_set = false;
  static bool physical = false;
  if (!physical_set) {
    physical_set = true;
    physical = use_physical();
  }
  return physical;
}

static inline double
pdpi_from_physical(int hpx, int vpx, double hinches, double vinches)
{
  double den2 = hinches * hinches + vinches * vinches;
  if (den2 <= 0.0) {
    return base_dpi;
  }
  double den1 = (double)hpx * (double)hpx + (double)vpx * (double)vpx;
  return sqrt(den1)/sqrt(den2);
}

unsigned int
_sqEnvironmentStops(void)
{
  unsigned int stops = 4;
  const char* var_value = getenv("_SQUEAK_DISPLAY_SCALE_STOPS");
  if (var_value) {
    unsigned int val = (unsigned int)strtoul(var_value, NULL, 10);
    if (!(val == 0 && errno == EINVAL)) {
      stops = val;
    }
  }
  return stops;
}


static inline double
ldpi_from_physical(int hpx, int vpx, double hinches, double vinches)
{
  unsigned int stops = _sqEnvironmentStops();
  double pdpi = pdpi_from_physical(hpx, vpx, hinches, vinches);
  /* determine scale, round towards default_scale */
  double pscale = (pdpi / base_dpi) - default_scale;
  double lscale = (trunc(pscale * stops) / stops) + default_scale;
  double ldpi= lscale * base_dpi;
  DPRINTF(("Displayscale: pdi: %f, pscale: %f, lscale: %f, ldpi: %f\n",
           pdpi, pscale+default_scale, lscale, ldpi));
  return ldpi;
}

/*
 * Produce a scale factor from pixel resolution and physical monitor
 * size. 
 * This function respects the prefer-physical setting.
 *
 */
double
sqScaleFromPhysical(int hpx, int vpx, double hinches, double vinches)
{
  static bool physical_set = false;
  static bool physical = false;
  if (!physical_set) {
    physical_set = true;
    physical = use_physical();
  }

  double dpi = physical
      ? pdpi_from_physical(hpx, vpx, hinches, vinches)
      : ldpi_from_physical(hpx, vpx, hinches, vinches);
  double scale = dpi / base_dpi;
  return scale;
}


#define BAIL_IF(expr) do { if ((expr)) { goto bail; } } while (0)
#define BAIL_IF_NULL(expr) BAIL_IF(NULL==(expr))
/*
 * User selected scale factor.
 * This is picked up from the environment.
 * The candidates are tried in decreasing priority (first=best)
 *
 */
static const char* _env_governing_var = NULL;
static const char* _env_candidates[] = {
  /* Our own  */
  DISPLAY_SCALE_FACTOR,
  /* */
  "CLUTTER_SCALE",
  "GDK_SCALE",
  "GDK_DPI_SCALE",
  "QT_AUTO_SCREEN_SCALE_FACTOR",
  "QT_SCALE_FACTOR",
  "QT_SCREEN_SCALE_FACTORS",
  "QT_DEVICE_PIXEL_RATIO",
  NULL
};
/*
 * We check the environmet for present variable that can be a source
 * of scale factor. Since the external environment cannot change
 * during the process' lifetime, it is ok to do the check and the
 * "extraction" just once.
 */
bool
sqUseEnvironmentScale(void)
{
  static bool env_set = false;
  static bool use_env = false;
  if (!env_set) {
    env_set = true;
    for (const char* const* var=_env_candidates; *var!=NULL; var++) {
      DPRINTF(("Displayscale: Env trying %s\n", *var));
      if (getenv(*var) != NULL) {
        DPRINTF(("Displayscale: Env using %s\n", *var));
        _env_governing_var = *var;
        use_env = true;
        break;
      }
    }
  }
  return use_env;
}
/*
 * Produce a scale factor from a scale-relevant variable in the
 * environment.
 *
 */
double
sqEnvironmentScale(void)
{
  BAIL_IF(!sqUseEnvironmentScale());
  BAIL_IF_NULL(_env_governing_var);
  const char* var_value = getenv(_env_governing_var);
  BAIL_IF_NULL(var_value);
  DPRINTF(("Displayscale: Env using %s with %s\n", _env_governing_var, var_value));
  double factor = strtod(var_value, NULL);
  BAIL_IF(!isnormal(factor));
  BAIL_IF(factor <= 0.0);

  return factor;
 bail:
  return default_scale;    
}



