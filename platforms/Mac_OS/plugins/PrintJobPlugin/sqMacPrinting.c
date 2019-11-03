/****************************************************************************
*   PROJECT: Mac printing
*   FILE:    sqMacPrinting.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacPrinting.c 1206 2005-06-02 20:21:11Z johnmci $
*
*   NOTES: 
*	Take carbon sample code, and alter it a bit
*	Feb 20th 2002, JMM - add offset logic, free printsession only if allocated (duh)
*   Jun 27th 2002, JMM - use UILock code to lock UI to prevent os-x seg fault
*       Aug 7th, 2002, JMM - fixes to build as internal
*
*****************************************************************************/
#include "sqVirtualMachine.h"
#include "sqMacPrinting.h"

/*------------------------------------------------------------------------------

    This sample code is the Carbon equivalent of the classic print loop
    documented in Tech Note 1092 "A Print Loop That Cares ...".  This code
    illustrates the use of functions defined in PMCore.h and PMApplication.h
    instead of Printing.h.

    You may incorporate this sample code into your applications without
    restriction, though the sample code has been provided "AS IS" and the
    responsibility for its operation is 100% yours.  However, what you are
    not permitted to do is to redistribute the source as "Apple Sample Code"
    after having made changes. If you're going to re-distribute the source,
    we require that you make it clear in the source that the code was
    descended from Apple Sample Code, but that you've made changes.
    
    Version:	1.0.1
    
    Technology:	Carbon Printing for Mac OS 8, 9 & X

    Copyright © 1998-2001 Apple Computer, Inc  ., All Rights Reserved
	
    Change History:

------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------
	Globals
------------------------------------------------------------------------------*/
static CTabHandle	stColorTable = nil;
static PixMapHandle	stPixMap = nil;
extern struct VirtualMachine *interpreterProxy;

/*------------------------------------------------------------------------------
	Prototypes
------------------------------------------------------------------------------*/
static void 	SetColorEntry(int index, int red, int green, int blue);
static void 	SetUpPixmap(void);
static void 	FreePixmap(void);
static Boolean RunningOnCarbonX(void);
OSStatus	DoPrintLoop(PrintingLogicPtr printJob);
OSStatus 	DrawPage(PrintingLogicPtr printJob);

#if TARGET_API_MAC_CARBON
OSStatus 	DoPageSetupDialog(PrintingLogicPtr printJob);
OSStatus 	DoPrintDialog(PrintingLogicPtr printJob);
OSStatus 	FlattenAndSavePageFormat(PrintingLogicPtr printJob);
OSStatus 	LoadAndUnflattenPageFormat(PrintingLogicPtr printJob);
OSStatus	DetermineNumberOfPagesInDoc(UInt32 *numPages,PrintingLogicPtr printJob);
Boolean		IncludePostScriptInSpoolFile(PrintingLogicPtr printJob);

/*------------------------------------------------------------------------------
 	
    Description:
        Uses PMCreateSession/PMRelease instead of PMBegin/PMEnd.  Note that the two
        printing objects, PMPageSetup and PMPrintSettings are valid outside the
        printing session.  This was not the case with PMBegin/PMEnd in the previous
        version of this sample code.  Note also that no nesting of printing sessions
        is allowed for Carbon applications running under MacOS 8 or 9.
 	
------------------------------------------------------------------------------*/
int ioPrintSetup(PrintingLogicPtr *token)
{
    OSStatus		status = noErr;
    PrintingLogicPtr printJob;
   
    printJob = *token = calloc(1,sizeof(PrintingLogic));
    printJob->printSession = NULL;
    printJob->pageFormat = kPMNoPageFormat;
    printJob->printSettings = kPMNoPrintSettings;
    printJob->flatFormatHandle = NULL;
    printJob->numberOfPages = 0;
    
    //	Initialize the printing manager and create a printing session.
    status = PMCreateSession(&printJob->printSession);
    if (status != noErr) 
        return -1;	// pointless to continue if PMCreateSession fails
    
    //	Display the Page Setup dialog.
    if (status == noErr) {
        status = DoPageSetupDialog(printJob);
    }
    return status;
}

int ioPrintPreProcessing(PrintingLogicPtr printJob,int numberOfPages) {
    OSStatus		status = noErr;
    UInt32	realNumberOfPagesinDoc;
    
    //	Display the Print dialog.
    
    if (printJob->printSession == NULL) 
        return -1;
        
    printJob->numberOfPages = numberOfPages;
    printJob->allowPostscript = false;
    
    status = DoPrintDialog(printJob);
    
    if (status == noErr) {
	    //issues with os 9 don't do CFStringRef	jobName = CFSTR("Squeak");
        //issues with os 9 don't do status = PMSetJobNameCFString(printJob->printSettings, jobName);
    
        //	Get the user's Print dialog selection for first and last pages to print.
        if (status == noErr)
            { 
            status = PMGetFirstPage(printJob->printSettings, &printJob->firstPage);
            if (status == noErr)
                status = PMGetLastPage(printJob->printSettings, &printJob->lastPage);
            }
    
        //	Check that the selected page range does not exceed the actual number of
        //	pages in the document.
        if (status == noErr)
            {
            status = DetermineNumberOfPagesInDoc(&realNumberOfPagesinDoc,printJob);
            if (realNumberOfPagesinDoc < printJob->lastPage)
                printJob->lastPage = realNumberOfPagesinDoc;
            }
    
        //	Before executing the print loop, tell the Carbon Printing Manager which pages
        //	will be spooled so that the progress dialog can reflect an accurate page count.
        //	This is recommended on Mac OS X.  On Mac OS 8 and 9, we have no control over
        //	what the printer driver displays.
            
        if (status == noErr)
            status = PMSetFirstPage(printJob->printSettings, printJob->firstPage, false);
        if (status == noErr)
            status = PMSetLastPage(printJob->printSettings, printJob->lastPage, false);
	if (status == noErr)
            status = PMSetPageRange(printJob->printSettings, 1, printJob->lastPage-printJob->firstPage+1);
        //	Check if we can add PostScript to the spool file
        if (status == noErr)
            printJob->allowPostscript = IncludePostScriptInSpoolFile(printJob);
        
        //	Begin a new print job.
        status = PMSessionBeginDocument(printJob->printSession, printJob->printSettings, printJob->pageFormat);
        }

    return status;
}

int ioPagePreProcessing(PrintingLogicPtr printJob) {                                               
    OSStatus		status = noErr;

    status = PMSessionBeginPage(printJob->printSession, printJob->pageFormat, NULL);
    return status;
}

int ioPrint(PrintingLogicPtr printJob) {  
    OSStatus		status = noErr;

    if (printJob->printSession == NULL) 
        return -1;
        
    //	Execute the print loop.
    if (status == noErr)
        status = DoPrintLoop(printJob);
 
    if(status == kPMCancel)
        status = noErr;
        
    return status;
}

int ioPagePostProcessing(PrintingLogicPtr printJob) {                                               
    OSStatus		status = noErr;
    
    //	Close the page.
    status = PMSessionEndPage(printJob->printSession);
    return status;
}


int ioPrintPostProcessing(PrintingLogicPtr printJob) {                                                                	OSStatus	status = noErr;

     // Close the print job.  This dismisses the progress dialog on Mac OS X.
    status = PMSessionEndDocument(printJob->printSession);
    return status;
    
}    

int ioPrintGetFirstPageNumber(PrintingLogicPtr printJob){
    if (printJob->printSession == NULL) 
        return 0;
    return printJob->firstPage;

}
int ioPrintGetLastPageNumber(PrintingLogicPtr printJob){
    if (printJob->printSession == NULL) 
        return 0;
    return printJob->lastPage;
}


int ioPrintCleanup(PrintingLogicPtr *token) {                                                                	PrintingLogicPtr printJob;
    //	Release the PageFormat and PrintSettings objects.  PMRelease decrements the
    //	ref count of the allocated objects.  We let the Printing Manager decide when
    //	to release the allocated memory.
    
    printJob = *token;
    if (printJob == nil) 
        return 0;
        
    if (printJob->pageFormat != kPMNoPageFormat)
        (void)PMRelease(printJob->pageFormat);
        
    if (printJob->printSettings != kPMNoPrintSettings)
        (void)PMRelease(printJob->printSettings);
    
    //	Terminate the current printing session. 
    if (printJob->printSession != NULL)
    	(void)PMRelease(printJob->printSession);
    
    printJob->pageFormat = kPMNoPageFormat;
    printJob->printSettings = kPMNoPrintSettings;
    printJob->printSession = NULL;
    free(printJob);
    *token = nil;
    
    return 0;
}

/*------------------------------------------------------------------------------

    Function:	DoPageSetupDialog
    
    Parameters:
    
    Description:
        If the caller passes in an empty PageFormat object, DoPageSetupDialog
        creates a new one, otherwise it validates the one provided by the caller.
        It then invokes the Page Setup dialog and checks for Cancel. Finally it
        flattens the PageFormat object so it can be saved with the document.
        Note that the PageFormat object is modified by this function.
	
------------------------------------------------------------------------------*/
OSStatus 	DoPageSetupDialog(PrintingLogicPtr printJob)
{
	OSStatus	status = noErr;
	Boolean		accepted;
        
	//	Set up a valid PageFormat object.
	if (printJob->pageFormat == kPMNoPageFormat)
            {
            status = PMCreatePageFormat(&printJob->pageFormat);
		
            //	Note that PMPageFormat is not session-specific, but calling
            //	PMSessionDefaultPageFormat assigns values specific to the printer
            //	associated with the current printing session.
            if ((status == noErr) && (printJob->pageFormat != kPMNoPageFormat))
                status = PMSessionDefaultPageFormat(printJob->printSession, printJob->pageFormat);
            }
	else
            status = PMSessionValidatePageFormat(printJob->printSession, printJob->pageFormat, kPMDontWantBoolean);
            
        /* This is broken
            fn = interpreterProxy->ioLoadFunctionFrom("getSTWindow", "");
	
        if (fn != 0) {
            WindowPtr	windowRef;
            windowRef = (WindowPtr) ((int (*) ()) fn)();
            PMSessionUseSheets(printJob->printSession,windowRef,NULL);
	} */
        
	//	Display the Page Setup dialog.	
	if (status == noErr)
            {
            void * giLocker;
            giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
            if (giLocker != 0) {
                long *foo;
                foo = malloc(sizeof(long)*6);
                foo[0] = 3;
                foo[1] = (long) PMSessionPageSetupDialog;
                foo[2] =  (long)printJob->printSession;
                foo[3] =  (long)printJob->pageFormat;
                foo[4] =  (long)&accepted;
                foo[5] = 0;
                ((int (*) (void *)) giLocker)(foo);
                status = foo[5];
                free(foo);
            } else
                    status = PMSessionPageSetupDialog(printJob->printSession, printJob->pageFormat,
                        &accepted);
            
            if (status == noErr && !accepted)
                status = kPMCancel;		// user clicked Cancel button
            }	
				
	//	If the user did not cancel, flatten and save the PageFormat object
	//	with our document.
	if (status == noErr)
            status = FlattenAndSavePageFormat(printJob);

	return status;
	
}	//	DoPageSetupDialog



/*------------------------------------------------------------------------------
	Function:	DoPrintDialog
		
	Parameters:
			
	Description:
		If the caller passes an empty PrintSettings object, DoPrintDialog creates
		a new one, otherwise it validates the one provided by the caller.
		It then invokes the Print dialog and checks for Cancel.
		Note that the PrintSettings object is modified by this function.
		
------------------------------------------------------------------------------*/
OSStatus 	DoPrintDialog(PrintingLogicPtr printJob)
{
	OSStatus	status = noErr;
	Boolean		accepted;
	UInt32		realNumberOfPagesinDoc;
	
	//	In this sample code the caller provides a valid PageFormat reference but in
	//	your application you may want to load and unflatten the PageFormat object
	//	that was saved at PageSetup time.  See LoadAndUnflattenPageFormat below.
	
	//	Set up a valid PrintSettings object.
	if (printJob->printSettings == kPMNoPrintSettings)
            {
            status = PMCreatePrintSettings(&printJob->printSettings);	

            //	Note that PMPrintSettings is not session-specific, but calling
            //	PMSessionDefaultPrintSettings assigns values specific to the printer
            //	associated with the current printing session.
            if ((status == noErr) && (printJob->printSettings != kPMNoPrintSettings))
                status = PMSessionDefaultPrintSettings(printJob->printSession, printJob->printSettings);
            }
	else
            status = PMSessionValidatePrintSettings(printJob->printSession, printJob->printSettings, kPMDontWantBoolean);
	
	//	Before displaying the Print dialog, we calculate the number of pages in the
	//	document.  On Mac OS X this is useful because we can prime the Print dialog
	//	with the actual page range of the document and prevent the user from entering
	//	out-of-range numbers.  This is not possible on Mac OS 8 and 9 because the driver,
	//	not the printing manager, controls the page range fields in the Print dialog.

	//	Calculate the number of pages required to print the entire document.
	if (status == noErr)
            status = DetermineNumberOfPagesInDoc(&realNumberOfPagesinDoc,printJob);

	//	Set a valid page range before displaying the Print dialog
	if (status == noErr)
            status = PMSetPageRange(printJob->printSettings, 1, realNumberOfPagesinDoc);

	//	Display the Print dialog.
	if (status == noErr)
            {
            void * giLocker;
            giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
            if (giLocker != 0) {
                long *foo;
                foo = malloc(sizeof(long)*7);
                foo[0] = 4;
                foo[1] =  (long)PMSessionPrintDialog;
                foo[2] =  (long)printJob->printSession;
                foo[3] =  (long)printJob->printSettings;
                foo[4] =  (long)printJob->pageFormat;
                foo[5] =  (long)&accepted;
                foo[6] = 0;
                ((int (*) (void *)) giLocker)(foo);
                status = foo[6];
                free(foo);
            } else
                status = PMSessionPrintDialog(printJob->printSession, printJob->printSettings,
                        printJob->pageFormat, &accepted);
            if (status == noErr && !accepted)
                status = kPMCancel;		// user clicked Cancel button
            }
		
	return status;
	
}	//	DoPrintDialog


/*------------------------------------------------------------------------------
	Function:
		DoPrintLoop
	
	Parameters:
	
	Description:
		DoPrintLoop calculates which pages to print and executes the print
		loop, calling DrawPage for each page.
				
------------------------------------------------------------------------------*/
OSStatus DoPrintLoop(PrintingLogicPtr printJob)
{
    OSStatus	status = noErr, tempErr;
    GrafPtr	currPort, printingPort;
                 
	
    //	Note, we don't have to worry about the number of copies.  The printing
    //	manager handles this.  So we just iterate through the document from the
    //	first page to be printed, to the last.

    //	Note, we don't have to deal with the classic Printing Manager's
    //	128-page boundary limit.
                    
    //	Set up a page for printing.  Under the classic Printing Manager, applications
    //	could provide a page rect different from the one in the print record to achieve
    //	scaling. This is no longer recommended and on Mac OS X, the PageRect argument
    //	is ignored.
    

    //	Save the current QD grafport.
    GetPort(&currPort);
        
    //	Get the current graphics context, in this case a Quickdraw grafPort,
    //	for drawing the page.
    status = PMSessionGetGraphicsContext(printJob->printSession, 
            kPMGraphicsContextQuickdraw, (void**) &printingPort);
    if (status == noErr) {
        
        //	Set the printing port before drawing the page.
        SetPort((GrafPtr) printingPort);
                            
        //	Draw the page.
        status = DrawPage(printJob);

        //	Restore the QD grafport.
        SetPort(currPort);
    }
            
    //	Only report a printing error once we have completed the print loop. This
    //	ensures that every PMBeginXXX call that returns no error is followed by
    //	a matching PMEndXXX call, so the Printing Manager can release all temporary 
    //	memory and close properly.
    tempErr = PMSessionError(printJob->printSession);
    if(status == noErr)
        status = tempErr;

    if (status == kPMCancel) 
        status = noErr;
            
    return status;
}	//	DoPrintLoop



/*------------------------------------------------------------------------------
	Function:
		FlattenAndSavePageFormat
	
	Parameters:
		pageFormat	-	a PageFormat object
	
	Description:
		Flattens a PageFormat object so it can be saved with the document.
		Assumes caller passes a validated PageFormat object.
		
------------------------------------------------------------------------------*/
OSStatus FlattenAndSavePageFormat(PrintingLogicPtr printJob)
{
    OSStatus	status;
    
    printJob->flatFormatHandle = NULL;
    
    //	Flatten the PageFormat object to memory.
    status = PMFlattenPageFormat(printJob->pageFormat, &printJob->flatFormatHandle);

    return status;
}	//	FlattenAndSavePageFormat



/*------------------------------------------------------------------------------
    Function:	LoadAndUnflattenPageFormat
	
    Parameters:
        pageFormat	- PageFormat object read from document file
	
    Description:
        Gets flattened PageFormat data from the document and returns a PageFormat
        object.
        The function is not called in this sample code but your application
        will need to retrieve PageFormat data saved with documents.
		
------------------------------------------------------------------------------*/
OSStatus	LoadAndUnflattenPageFormat(PrintingLogicPtr printJob)
{
    OSStatus	status = noErr;

    if(printJob->flatFormatHandle){
        //	Convert the PageFormat flattened data into a PageFormat object.
        status = PMUnflattenPageFormat(printJob->flatFormatHandle,&printJob->pageFormat);
    }else{
        printJob->pageFormat = kPMNoPageFormat;
    }
    
    return status;
}	//	LoadAndUnflattenPageFormat



/*------------------------------------------------------------------------------
    Function:	DetermineNumberOfPagesInDoc
	
    Parameters:
    	pageFormat	- a PageFormat object addr
        numPages	- on return, the size of the document in pages
			
    Description:
    	Calculates the number of pages needed to print the entire document.
		
------------------------------------------------------------------------------*/
OSStatus	DetermineNumberOfPagesInDoc(UInt32 *numPages,PrintingLogicPtr printJob)
{
    OSStatus	status;
    PMRect	pageRect;

    //	PMGetAdjustedPageRect returns the page size taking into account rotation,
    //	resolution and scaling settings.
    status = PMGetAdjustedPageRect(printJob->pageFormat, &pageRect);

    //	In this sample code we simply return a hard coded number.  In your application,
    //	you will need to figure out how many page rects are needed to image the
    //	current document.
    *numPages = printJob->numberOfPages;

    return status;
    
}	//	DetermineNumberOfPagesinDoc





/*------------------------------------------------------------------------------
    Function:	IncludePostScriptInSpoolFile
	
    Parameters:
        printSession	- current printing session
	
    Description:
    	Check if current printer driver supports embedding of PostScript in the spool file, and
        if it does, instruct the Carbon Printing Manager to generate a PICT w/ PS spool file.
                		
------------------------------------------------------------------------------*/
Boolean IncludePostScriptInSpoolFile(PrintingLogicPtr printJob)
{
    Boolean	includePostScript = false;
    OSStatus	status;
    CFArrayRef	supportedFormats = NULL;
    SInt32	i, numSupportedFormats;

    // Get the list of spool file formats supported by the current driver.
    // PMSessionGetDocumentFormatGeneration returns the list of formats which can be generated
    // by the spooler (client-side) AND converted by the despooler (server-side).
    // PMSessionGetDocumentFormatSupported only returns the list of formats which can be converted
    // by the despooler.
    
    status = PMSessionGetDocumentFormatGeneration(printJob->printSession, &supportedFormats);
    if (status == noErr)
    {
        // Check if PICT w/ PS is in the list of supported formats.
        numSupportedFormats = CFArrayGetCount(supportedFormats);
        
        for (i=0; i < numSupportedFormats; i++)
        {
           /* if ( CFStringCompare(CFArrayGetValueAtIndex(supportedFormats, i),
                kPMDocumentFormatPDF, kCFCompareCaseInsensitive) == kCFCompareEqualTo )
                    return true;
                    
            if ( CFStringCompare(CFArrayGetValueAtIndex(supportedFormats, i),
                kPMDocumentFormatPostScript, kCFCompareCaseInsensitive) == kCFCompareEqualTo )
                    return true;*/
                    
            if ( CFStringCompare(CFArrayGetValueAtIndex(supportedFormats, i),
                kPMDocumentFormatPICTPS, kCFCompareCaseInsensitive) == kCFCompareEqualTo )
            {
                // PICT w/ PS is supported, so tell the Printing Mgr to generate a PICT w/ PS spool file
                
                // Build an array of graphics contexts containing just one type, Quickdraw,
                // meaning that we will be using a QD port to image our pages in the print loop.
                CFStringRef	strings[1];
                CFArrayRef	arrayOfGraphicsContexts;
				
                strings[0] = kPMGraphicsContextQuickdraw;
                arrayOfGraphicsContexts = CFArrayCreate(kCFAllocatorDefault,
                        (const void **)strings, 1, &kCFTypeArrayCallBacks);
										
                if (arrayOfGraphicsContexts != NULL)
                {
                        // Request a PICT w/ PS spool file
                        status = PMSessionSetDocumentFormatGeneration(printJob->printSession, kPMDocumentFormatPICTPS, 
                            arrayOfGraphicsContexts, NULL);
					
                        if (status == noErr) {
                             includePostScript = true;	// Enable use of PS PicComments in DrawPage.
                        }
                        // Deallocate the array used for the list of graphics contexts.
                            CFRelease(arrayOfGraphicsContexts);
                }
		break;
            }
        }
                    
        // Deallocate the array used for the list of supported spool file formats.
        CFRelease(supportedFormats);
    }
            
    return includePostScript;
}	//	IncludePostScriptInSpoolFile

#else
int ioPrintSetup(PrintingLogicPtr *token)
{
    OSStatus		status = noErr;
    PrintingLogicPtr printJob;
   
    printJob = *token = (PrintingLogicPtr) NewPtrClear(sizeof(PrintingLogic));
    printJob->thePrRecHdl = (THPrint)  NewHandle (sizeof (TPrint));
	status = MemError();
    if (status != noErr) 
        return -1;	// pointless to continue if memory allocation fails
    
    //	Initialize the printing manager and create a printing session.
 	PrOpen(); //The PrOpen procedure prepares the current printer driver for use. 
 	status = PrError();
    if (status != noErr) 
    	return status;	
 	
 	PrintDefault(printJob->thePrRecHdl);
	status = PrError();
    if (status != noErr) 
    	return status;	

	PrValidate(printJob->thePrRecHdl);
	status = PrError();
    if (status != noErr) 
    	return status;	

    //	Display the Page Setup dialog.
	if (! PrStlDialog(printJob->thePrRecHdl)) 
  	    goto cleanup; // user cancelled

    
    return status;
    cleanup: 
    	DisposeHandle ((Handle) printJob->thePrRecHdl);
    	printJob->thePrRecHdl = NULL;
    	return -4;
}

int ioPrintPreProcessing(PrintingLogicPtr printJob,int numberOfPages) {
    OSStatus		status = noErr;
    UInt32	realNumberOfPagesinDoc;
        
    if (printJob->thePrRecHdl == NULL) 
        return -1;
        
    printJob->numberOfPages = numberOfPages;
    printJob->allowPostscript = false;
    
    if (!PrJobDialog(printJob->thePrRecHdl))
    	return -2;
    
    if (status == noErr) {
        //	Get the user's Print dialog selection for first and last pages to print.
        if (status == noErr)
            { 
            TPPrint foo = *printJob->thePrRecHdl;
            printJob->firstPage = foo->prJob.iFstPage;
            printJob->lastPage =  foo->prJob.iLstPage;
            }
    
        //	Check that the selected page range does not exceed the actual number of
        //	pages in the document.
        if (status == noErr)
            {
            realNumberOfPagesinDoc = printJob->numberOfPages;
            if (realNumberOfPagesinDoc < printJob->lastPage)
                printJob->lastPage = realNumberOfPagesinDoc;
            }
        
        //	Begin a new print job.
		printJob->thePrPort = PrOpenDoc(printJob->thePrRecHdl, nil, nil);
		status = PrError();
        }

    return status;
}

int ioPagePreProcessing(PrintingLogicPtr printJob) {                                               
    OSStatus		status = noErr;

	PrOpenPage(printJob->thePrPort, nil);
 	status = PrError();
    return status;
}

int ioPrint(PrintingLogicPtr printJob) {  
    OSStatus		status = noErr;

    if (printJob->thePrRecHdl == NULL) 
        return -1;
        
    //	Execute the print loop.
    if (status == noErr)
        status = DoPrintLoop(printJob);
 
    if(status == kPMCancel)
        status = noErr;
        
    return status;
}

int ioPagePostProcessing(PrintingLogicPtr printJob) {                                               
    OSStatus		status = noErr;
    
    //	Close the page.
	PrClosePage(printJob->thePrPort);
 	status = PrError();
    return status;
}


int ioPrintPostProcessing(PrintingLogicPtr printJob) {                                                                	OSStatus	status = noErr;

     // Close the print job.  This dismisses the progress dialog on Mac OS X.
 	PrCloseDoc(printJob->thePrPort);
 	status = PrError();
    return status;
}    

int ioPrintGetFirstPageNumber(PrintingLogicPtr printJob){
    if (printJob->thePrRecHdl == NULL) 
        return 0;
    return printJob->firstPage;

}
int ioPrintGetLastPageNumber(PrintingLogicPtr printJob){
    if (printJob->thePrRecHdl == NULL) 
        return 0;
    return printJob->lastPage;
}


int ioPrintCleanup(PrintingLogicPtr *token) {                                                                	PrintingLogicPtr printJob;
    //	Release the PageFormat and PrintSettings objects.  PMRelease decrements the
    //	ref count of the allocated objects.  We let the Printing Manager decide when
    //	to release the allocated memory.
    
    printJob = *token;
    if (printJob == nil) 
        return 0;
            
    //	Terminate the current printing session. 
	PrClose();
    
    if(printJob->thePrRecHdl != NULL) 
 		DisposeHandle ((Handle) printJob->thePrRecHdl);
   	
    printJob->thePrRecHdl = NULL;
    DisposePtr((char*)printJob);
    *token = nil;
    
    return 0;
}

OSStatus DoPrintLoop(PrintingLogicPtr printJob)
{
    OSStatus	status = noErr;
    GrafPtr	currPort;
                 
    //	Save the current QD grafport.
    GetPort(&currPort);
        
    //	Get the current graphics context, in this case a Quickdraw grafPort,
    //	for drawing the page.
    status = printJob->thePrPort == NULL ? -3 : noErr;
    
    if (status == noErr) {
        
        //	Set the printing port before drawing the page.
        SetPort((GrafPtr) printJob->thePrPort);
                            
        //	Draw the page.
        status = DrawPage(printJob);

        //	Restore the QD grafport.
        SetPort(currPort);
    }
            
    return status;
}	//	DoPrintLoop

#endif

int ioInitPrintJob() {
    SetUpPixmap();
    return 1;
}

int ioShutdownPrintJob() {
    FreePixmap();
    return 1;
}

static Boolean RunningOnCarbonX(void)
{
    UInt32 response;
    
    return (Gestalt(gestaltSystemVersion, 
                    (SInt32 *) &response) == noErr)
                && (response >= 0x01000);
}

int ioPagePostscript(PrintingLogicPtr printJob,char *postscript,int postscriptLength) {

    printJob->postscript = postscript;
    printJob->postscriptLength = postscriptLength;
    printJob->formBitMap = NULL;
    return ioPrint(printJob);
}

int ioPageForm(PrintingLogicPtr printJob, char *aBitMap,int h,int w,int d,float sh,float sw,int oh, int ow) {
    printJob->formBitMap = aBitMap;
    printJob->width = w;
    printJob->height = h;
    printJob->depth = d;
    printJob->scaleH = sh;
    printJob->scaleW = sw;
    printJob->offsetHeight = oh;
    printJob->offsetWidth = ow;
    printJob->postscriptLength = 0;
    return ioPrint(printJob);
}

/*------------------------------------------------------------------------------
    Function:	DrawPage
	
    Parameters:
	
    Description:
        Draws the contents of a single page.  If allowPostscript is true, DrawPage
        adds PostScript code into the spool file.  See the Printing chapter in
        Inside Macintosh, Imaging with QuickDraw, for details about PostScript
        PicComments.
		
------------------------------------------------------------------------------*/
OSStatus DrawPage(PrintingLogicPtr printJob)
{
    OSStatus status = noErr; 
    CGrafPtr  printerPort;
    Rect	dstRect = { 0, 0, 0, 0 };
    Rect	srcRect = { 0, 0, 0, 0 };
    
    if (printJob->formBitMap != nil) {
        dstRect.top = printJob->offsetHeight;
        dstRect.left = printJob->offsetWidth;
        dstRect.right = printJob->width*printJob->scaleW + printJob->offsetWidth;
        dstRect.bottom = printJob->height*printJob->scaleH + printJob->offsetHeight;
    
        srcRect.right = printJob->width;
        srcRect.bottom = printJob->height;

        HLock((Handle)stPixMap);
        (*stPixMap)->baseAddr = (void *) printJob->formBitMap;
        (*stPixMap)->rowBytes = (((((printJob->width * printJob->depth) + 31) / 32) * 4) & 0x1FFF) | 0x8000;
        (*stPixMap)->bounds = srcRect;
        (*stPixMap)->pixelSize = printJob->depth;
    
        if (printJob->depth<=8) { 
            (*stPixMap)->cmpSize = printJob->depth;
            (*stPixMap)->cmpCount = 1;
        } else if (printJob->depth==16) {
            (*stPixMap)->cmpSize = 5;
            (*stPixMap)->cmpCount = 3;
        } else if (printJob->depth==32) {
            (*stPixMap)->cmpSize = 8;
            (*stPixMap)->cmpCount = 3;
        }

        GetPort((GrafPtr *) &printerPort);
        
        if (RunningOnCarbonX()) {
            CopyBits((BitMap *) *stPixMap, GetPortBitMapForCopyBits(printerPort), &srcRect, &dstRect, srcCopy, NULL);
        } else {
            GWorldPtr   aGWorld;
            PixMapHandle thePix;
            
            NewGWorld(&aGWorld, printJob->depth, &srcRect, stColorTable, NULL, keepLocal+useTempMem);
            thePix = GetGWorldPixMap (aGWorld);
    	    LockPixels(thePix);
         
            CopyBits((BitMap *) *stPixMap, (BitMap *) *thePix, &srcRect, &srcRect, srcCopy, NULL);
            CopyBits((BitMap *) *thePix, GetPortBitMapForCopyBits(printerPort), &srcRect, &dstRect, srcCopy, NULL);
    	   
    	    UnlockPixels(thePix);
            DisposeGWorld(aGWorld);
        }
        HUnlock((Handle)stPixMap);
    }
        
#if TARGET_API_MAC_CARBON	
    //	Conditionally insert PostScript into the spool file.
    if (printJob->allowPostscript && printJob->postscriptLength > 0) {
         status = PMSessionPostScriptBegin(printJob->printSession);
        if (status == noErr)
        {
            status = PMSessionPostScriptData(printJob->printSession, 
                    (char *)printJob->postscript,printJob->postscriptLength);
            status = PMSessionPostScriptEnd(printJob->printSession);
        }
    }   
#else
	return PrError();
#endif
		
    return status;
}	//	DrawPage



static void SetUpPixmap(void) {
	int i, r, g, b;

	stColorTable = (CTabHandle) NewHandle(sizeof(ColorTable) + (256 * sizeof(ColorSpec)));
	(*stColorTable)->ctSeed = GetCTSeed();
	(*stColorTable)->ctFlags = 0;
	(*stColorTable)->ctSize = 255;

	/* 1-bit colors (monochrome) */
	SetColorEntry(0, 65535, 65535, 65535);	/* white or transparent */
	SetColorEntry(1,     0,     0,     0);	/* black */

	/* additional colors for 2-bit color */
	SetColorEntry(2, 65535, 65535, 65535);	/* opaque white */
	SetColorEntry(3, 32768, 32768, 32768);	/* 1/2 gray */

	/* additional colors for 4-bit color */
	SetColorEntry( 4, 65535,     0,     0);	/* red */
	SetColorEntry( 5,     0, 65535,     0);	/* green */
	SetColorEntry( 6,     0,     0, 65535);	/* blue */
	SetColorEntry( 7,     0, 65535, 65535);	/* cyan */
	SetColorEntry( 8, 65535, 65535,     0);	/* yellow */
	SetColorEntry( 9, 65535,     0, 65535);	/* magenta */
	SetColorEntry(10,  8192,  8192,  8192);	/* 1/8 gray */
	SetColorEntry(11, 16384, 16384, 16384);	/* 2/8 gray */
	SetColorEntry(12, 24576, 24576, 24576);	/* 3/8 gray */
	SetColorEntry(13, 40959, 40959, 40959);	/* 5/8 gray */
	SetColorEntry(14, 49151, 49151, 49151);	/* 6/8 gray */
	SetColorEntry(15, 57343, 57343, 57343);	/* 7/8 gray */

	/* additional colors for 8-bit color */
	/* 24 more shades of gray (does not repeat 1/8th increments) */
	SetColorEntry(16,  2048,  2048,  2048);	/*  1/32 gray */
	SetColorEntry(17,  4096,  4096,  4096);	/*  2/32 gray */
	SetColorEntry(18,  6144,  6144,  6144);	/*  3/32 gray */
	SetColorEntry(19, 10240, 10240, 10240);	/*  5/32 gray */
	SetColorEntry(20, 12288, 12288, 12288);	/*  6/32 gray */
	SetColorEntry(21, 14336, 14336, 14336);	/*  7/32 gray */
	SetColorEntry(22, 18432, 18432, 18432);	/*  9/32 gray */
	SetColorEntry(23, 20480, 20480, 20480);	/* 10/32 gray */
	SetColorEntry(24, 22528, 22528, 22528);	/* 11/32 gray */
	SetColorEntry(25, 26624, 26624, 26624);	/* 13/32 gray */
	SetColorEntry(26, 28672, 28672, 28672);	/* 14/32 gray */
	SetColorEntry(27, 30720, 30720, 30720);	/* 15/32 gray */
	SetColorEntry(28, 34815, 34815, 34815);	/* 17/32 gray */
	SetColorEntry(29, 36863, 36863, 36863);	/* 18/32 gray */
	SetColorEntry(30, 38911, 38911, 38911);	/* 19/32 gray */
	SetColorEntry(31, 43007, 43007, 43007);	/* 21/32 gray */
	SetColorEntry(32, 45055, 45055, 45055);	/* 22/32 gray */
	SetColorEntry(33, 47103, 47103, 47103);	/* 23/32 gray */
	SetColorEntry(34, 51199, 51199, 51199);	/* 25/32 gray */
	SetColorEntry(35, 53247, 53247, 53247);	/* 26/32 gray */
	SetColorEntry(36, 55295, 55295, 55295);	/* 27/32 gray */
	SetColorEntry(37, 59391, 59391, 59391);	/* 29/32 gray */
	SetColorEntry(38, 61439, 61439, 61439);	/* 30/32 gray */
	SetColorEntry(39, 63487, 63487, 63487);	/* 31/32 gray */

	/* The remainder of color table defines a color cube with six steps
	   for each primary color. Note that the corners of this cube repeat
	   previous colors, but simplifies the mapping between RGB colors and
	   color map indices. This color cube spans indices 40 through 255.
	*/
	for (r = 0; r < 6; r++) {
		for (g = 0; g < 6; g++) {
			for (b = 0; b < 6; b++) {
				i = 40 + ((36 * r) + (6 * b) + g);
				SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
			}
		}
	}

	stPixMap = NewPixMap();
	(*stPixMap)->pixelType = 0; /* chunky */
	(*stPixMap)->cmpCount = 1;
	(*stPixMap)->pmTable = stColorTable;
}

static void SetColorEntry(int index, int red, int green, int blue) {
	(*stColorTable)->ctTable[index].value = index;
	(*stColorTable)->ctTable[index].rgb.red = red;
	(*stColorTable)->ctTable[index].rgb.green = green;
	(*stColorTable)->ctTable[index].rgb.blue = blue;
}

static void FreePixmap(void) {
	if (stPixMap != nil) {
		DisposePixMap(stPixMap);
		stPixMap = nil;
	}

	if (stColorTable != nil) {
		//JMM disposepixmap does this DisposeHandle((void *) stColorTable);
		stColorTable = nil;
	}
}
