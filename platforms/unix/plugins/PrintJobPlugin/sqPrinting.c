#include "PrintJobPlugin.h"
#include <stdio.h>


/* none of these setup, cleanup, preprocess, postprocess,
   *etc. commands make any sense on Unix.  Well, I suppose such a
   *thing could* be implemented, but it would all have to be done by
   *hand */
int ioPrintSetup(PrintingLogicPtr  *printJob) 
{
  *printJob= (PrintingLogicPtr) 1234;  /* I would like to put NULL here, but NULL is considered an error.... */
  return 0;
}

int ioPrintPreProcessing(PrintingLogicPtr printJob,int numberOfPages)
{
  return 0;
}

int ioPrintPostProcessing(PrintingLogicPtr printJob)
{
  return 0;
}

int ioPrintCleanup(PrintingLogicPtr *printJob)
{
  return 0;
}

int ioInitPrintJob(void)
{
  return 1;  /* it would be nice to have a standard on which functions
                return 0 for success and which functions return
                non-zero... */
}

int ioShutdownPrintJob(void)
{
  return 1;
}

int ioPagePreProcessing(PrintingLogicPtr printJob)
{
  return 0;
}

int ioPagePostProcessing(PrintingLogicPtr printJob)
{
  return 0;
}




/* ioGetFirstPageNumber and ioGetLastPageNumber --
   Since the above operations aren't actually performed, there are no
   page numbers, or any other info, to be returned from the plugin.
   These functions just return page 1.  */
   
int ioPrintGetFirstPageNumber(PrintingLogicPtr printJob)
{
  return 1;
}


int ioPrintGetLastPageNumber(PrintingLogicPtr printJob)
{
  return 1;
}


/* ioPrint -- theoretically this should be where the printing happens,
   but that means recording each portion of the print job.  It should
   be fixed up at some point to do so; users should be able, for
   example, to cancel a print job.  Then again, for the common
   application of printing out the current desktop, it doesn't matter */
int ioPrint(PrintingLogicPtr printJob)
{
  return 0;
}



/* ioPagePostscript -- print out a posstcript file.  This just popen's lpr */
/* XXX the exact print command should probably be configurable */
int ioPagePostscript(PrintingLogicPtr printJob,char *postscript,int postscriptLength)
{
  FILE *lprOutput;
  size_t written;

  lprOutput=popen("lpr", "w");
  if(lprOutput == NULL) {
    perror("lpr");
    return 1;
  }

  written = fwrite(postscript, postscriptLength, 1, lprOutput);
  if(written < 1) {
    perror("fwrite");
    pclose(lprOutput);
    return 1;
  }

  pclose(lprOutput);
  return 0;
}


/* ioPageForm -- print out a form */
int ioPageForm(PrintingLogicPtr printJob, char *aBitMap,int h,int w,int d,float sh,float sw,int oh,int ow)
{
  /* just call the original primitive for form-printing */
  return ioFormPrint((int)aBitMap, w, h, d, sw, sh, 1);
}
