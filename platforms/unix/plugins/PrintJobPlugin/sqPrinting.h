/* sqPrinting.h for Unix */

typedef int PrintingLogic;
typedef PrintingLogic *PrintingLogicPtr;


int ioPrintSetup(PrintingLogicPtr  *printJob);
int ioPrintPreProcessing(PrintingLogicPtr printJob,int numberOfPages);
int ioPrint(PrintingLogicPtr printJob);
int ioPrintPostProcessing(PrintingLogicPtr printJob);
int ioPrintCleanup(PrintingLogicPtr *printJob);
int ioInitPrintJob(void);
int ioShutdownPrintJob(void);
int ioPagePreProcessing(PrintingLogicPtr printJob);
int ioPagePostProcessing(PrintingLogicPtr printJob);
int ioPagePostscript(PrintingLogicPtr printJob,char *postscript,int postscriptLength);
int ioPageForm(PrintingLogicPtr printJob, char *aBitMap,int h,int w,int d,float sh,float sw,int oh,int ow);
int ioPrintGetFirstPageNumber(PrintingLogicPtr printJob);
int ioPrintGetLastPageNumber(PrintingLogicPtr printJob);
