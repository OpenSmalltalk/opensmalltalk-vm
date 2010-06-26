/****************************************************************************
*   PROJECT: Mac printing
*   FILE:    sqMacPrinting.h
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacPrinting.h 210 2002-02-20 21:02:40Z johnmci $
*
*   NOTES: 
*
*****************************************************************************/
#if defined(__MWERKS__)
	#include <PMApplication.h>
#else
	#if TARGET_API_MAC_CARBON	
#include <Carbon/Carbon.h>
	#else
	#endif
#endif

typedef struct {
	UInt32	numberOfPages;
        UInt32	currentPage;
        UInt32	firstPage;
        UInt32	lastPage;
        Boolean	allowPostscript;
        void 	*formBitMap;
        long	width;
        long	height;
        long	depth;
        float	scaleW;
        float	scaleH;
        long	offsetWidth;
        long	offsetHeight;
        void	*postscript;
        UInt32	postscriptLength;
#if TARGET_API_MAC_CARBON	
        Handle 	flatFormatHandle;
        PMPrintSession printSession;
        PMPageFormat	pageFormat;
        PMPrintSettings printSettings;
#else
	    THPrint		thePrRecHdl;
		TPPrPort	thePrPort;
#endif
}  PrintingLogic, *PrintingLogicPtr;


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
