Updated  April 14th, 2009

Building the Squeak Virtual Machine (Aug 6th, 2002)
	-- John Maloney, May 25, 2000,
	-- Changes John M McIntosh Aug 2, 2000, Dec 1,2000, Feb 10th 2001, May 30th 2001, Dec 18th 2001, Jan 1st 2002,
	   Feb 5th 2002, April 26th 2002
	-- Changes Andrew C. Greenberg, Jan 1st 2002
   	-- Changes Jay Hardesty, July 6, 2002
    	-- Changes John Mcintosh &  Andrew C. Greenberg. Aug 6 & 7th, 2002
    	-- Changes John McIntosh Nov 14th, 2002 (some cleanup and modernization
    	-- CHanges John McIntosh April 5th, 2003 (changeset names change)
	-- Changes John McIntosh May 19th, 2003 (changeset consolidation into VMMaker).
	-- Changes John McIntosh July 31th, 2003 3.5.x updates
	-- Changes John McIntosh Oct 5th, 2003 3.6.x updates
	-- Changes John McIntosh Feb 18th, 2004 3.7.x updates (pending)  (xcode changes)
	-- Changes John McIntosh May 23rd, 2005 3.8.8b2 revise for SVN usage
	-- Changes John McIntosh Jun 4th, 2005 3.8.8b2 revised for 3.9
	-- Changes John McIntosh Nov 10th, 2005 3.8.9b8 revised SVN location, misc updates
	-- Changes John McIntosh Mar 5th, 2006 3.8.11b1 Drop os-9, non-carbon logic. 
	-- Changes John McIntosh Sept 3rd, 2006 3.8.12b5u clarify build instructions
	-- Changes John McIntosh, Craig Latta, Oct 19th, 2006 3.8.13b4
	-- Changes John McIntosh, Dec 11th, 2006 3.8.14b6U, clarify, cross check
	-- Changes John McIntosh, Feb 6th, 2007 3.8.15b3U, clarify, cross check
	-- Changes John McIntosh, Mar 4th, 2007 3.8.15b4u, extra changeset added 
	-- Changes John McIntosh, Apr 17th, 2007 3.8.16b5u, browser build notes 
	-- Changes John McIntosh, Apr 25th, 2007 3.8.17b2, build notes (large cursor support)
	-- Changes John McIntosh, Jun 9th, 2007 3.8.18b1, 32bit clean work
	-- Changes John McIntosh, April 14th, 2009 4.0, dtl david lewis work plus closures, review for 3.10.x install and where did 2008 go? 
	

(Note to readers, it is possible a step was missed, so beware)

Building a Carbon Squeak VM with XCode:

{JMM notes this is building with 10.5.x, and Squeak 3.10, to provide a closure VM with Alien Support }

Step One: Get the Apple Developer Tools (free)

	The current build requires the latest XCode tools.  They are available to Online members at the apple developer website.  You can get an Online membership for free at:

		http://developer.apple.com/membership/online.html
		
		(Note building with GCC 3.3 PowerPC produces better code than gcc 4.0, gcc 3.1 or gcc 2.95, FYI gcc 3.1 produces lousy code). 
		Of course you must build with GCC 4.x for MacIntel, but the XCode project does this automatically for you
		Building with GCC 4.0 is good, building with GCC 4.2 is bad.
		Ensure you install the 10.3.9 SDK tree etc from the XCode install process otherwise you won't be able to build the powerpc version. 
				
Step Two: Get the current SVN Platforms tree

	A.	Visit http://subversion.tigris.org/ to understand SVN, and I suspect install SVN on your machine.
		You should visit
			http://www.lachoseinteractive.net/en/community/subversion/svnx/download/
		to get the client gui. Checkout a working copy of the squeak/trunk, either via the GUI tool
		where you select the version you want to check out and hit the svn checkout button, then when prompted
		point to your build folder.  

		or from a terminal session go to the directory you want to build in, say your vmmaker image folder, 
		then enter svn co http://squeakvm.org/svn/squeak/trunk svnSqueakTree.

		I will note which version of the tree you check out is dependent on which version of the mac carbon VM you want to build
		you should check the tree version numbers and comments to identify the point in the versions where one version of 
		the VM ends and a new version starts. 

		
After so much mumbo-jumbo, your Squeak folder should have a directory entitled platforms.

Step Three: Build an interpeter

	0.  Grab your Pharo or squeak imge

	Install Balloon 3D via MC

	Install the Ballon3D-Constants & Ballon3D-Plugins
	MCHttpRepository		location: 'http://www.squeaksource.com/Balloon3D'		user: ''		password: ''
	

	Install FFI  & Klatt via MC
	MCHttpRepository
   		 location: 'http://www.squeaksource.com/Speech'
   		 user: ''
   		 password: ''

	SharedPool-Speech, Speech

	MCHttpRepository
  	  	location: 'http://source.squeak.org/FFI'
  	  	user: ''
  	 	password: ''
		
	FFI-Pools,FFI-Kernel


	Install Name: VMMaker-jcg.182 or higher from
	MCHttpRepository    		location: 'http://www.squeaksource.com/VMMaker'    		user: ''    		password: ''

	Install Alien Plugin


	A.  Install additional change sets from the specialChangeSets Folder. 
		Gnuifier.st - A smalltalk version of the AWK example. 	
		
	B.	Bring up the World menu, click open, click open VMMaker to get the VMMaker panel up. 
	C.	Enter the Path to platforms code: (enter path to platforms in step two).
		If you are running the image from the squeak build folder then it should auto-find platforms when it opens

	D.	Enter the Platform name: (default is fine) "Mac OS", it should auto-pick that.
	E.	Enter the Path for your generates sources (note src32 should be renamed to src to make XCode happy). 
	E2. 	Note mac carbon VM only supports a 32 bit VM since the entire carbon/osx api set is 32bit, not 64, do NOT pick 64 bit VM? 
	F.	Select plugins. (Suggest selecting menu item "make all internal",
		then drag back the following back to Plugins not built:
			CroquetPlugin
			FFIPlugin
			FloatMathPlugin
			FileCopyPlugin
			Mpeg3Plugin
			TestOSAPlugin
	
	G.	Press button "Save" to save your configuration for later.
	H.	Press button "Entire " to build the interpreter, it then builds a source tree in a folder called src.


Step Four: Get, and install, the Gnifier, and gnuify the interpreter

	A.	See the Gnuifier.st in the specialChangeSetsFolder
	B.	DoIt: 	(Gnuifier on: pathToInterpreterfile) gnuify, in my case:

		(Gnuifier on:
			((FileDirectory default
				directoryNamed: 'src')  "Perhaps src32 depending on how VMMaker 32/64 thinks about this"
				directoryNamed: 'vm') pathName) gnuify
	C. 	Note that if the src folder is called src32, you will need to rename it to src in order for xcode to find it.


Step Five: Shove and Tweak some files around the buildspace

	A.	Open a MacOSX Finder browser and go to the platforms/Mac OS/vm/Developer folder.
	B.	Unzip 'resources.zip' by double-clicking on it. Put the resulting resource folder in the folder containing
		the 'platforms' and 'src' folders.
	C.	Unstuff 'SqueakVMUNIXPATHS.xcodeproj.zip' (same deal as step B)
	D.	Drag 'SqueakVMUNIXPATHS.xcodeproj' to the folder containing
		the 'platforms' and 'src' folders.

	E.	Ensure a copy of the file (again found in the Developer directory):
			Squeak VM Universal-Info.plist
		can be found in the folder containing the 'platforms' and 'src' folders.

Step Six: Run ProjectBuilder and build yourself an interpreter {for xcode 1.5 or higher }

	A.	Double-click the SqueakVMUNIXPATHS.xcodeproj file
	B.	On the left pane, see the SqueakVMUNIXPATHS blue xcode icon.
		Click on  it to see the files.
		Files which can't be found are listed in red. For any red highlighted files you'll need to 
		resolve where or why the files is/are missing.
	c.	On the left pane, find the Targets icon. 
	d.	Select "Squeak VM Opt"
	e.	From the Project menu pick the active build configuration you want to use.
		Click on the hammer icon at the top  to build your VM.


		Problems: 
		1) It is possible depending on which updated SDK from apple that you have that you might get an error 
		in obj-class.h  parsing @class Protocol;   That is an error in Apple's source code. 

		You must then use sudo vi {path to the file}/obj-class.h to edit the read ony system file and 
		alter the @class Protocol to 

		#ifdef __OBJC__
			@class Protocol;
		#else
			typedef struct objc_object Protocol;
		#endif

		2) Corrections to 10.3.9 SDKs api for IOHIDLib.h. If you build with the 10.2.8SDK this file is not a problem. If you build with the 10.4U SDK this is not a problem. But if you build with the default 10.3.9 SDK then you get a redefinition of IOHIDQueueInterface and IOHIDOutputTransactionInterface error. To fix this you must change your 10.3.9 SDK version of IOHIDLib.h based on changes in the 10.4u SDK. 

		in the 10.4u SDK api's it's 

struct IOHIDQueueInterface
{
IUNKNOWN_C_GUTS;
IOHIDQUEUEINTERFACE_FUNCS_100;
};

and

struct IOHIDOutputTransactionInterface
{
IUNKNOWN_C_GUTS;
IOHIDOUTPUTTRANSACTIONINTERFACE_FUNCS_120;
};


		3) We use a sqNamedPrims.h in the Mac OS source tree, versus the sqNamedPrims.h that is created in the src
		directory. You may need to repoint the xcode source file to point to your sqNamedPrims.h if the internal plugins built are 
		different. 

		4) All this work only builds the VM, external plugins such as the mpeg plugin or services, spelling or quicktime can then 
		be copied over from a distributed production VM if required. 

		5) The final product should live in the build folder, a subfolder depending on build configuration and, the bundle is named "Squeak VM Opt"
		Run a tinyBenchmark benchmark against your VM, versus the production VM to confirm yours is simular in performance.

Step Seven: Download and print your Squeak VM Developer's Certificate

	http://www.rowledge.org/tim/squeak/SqueakVMBuilderCertificate.pdf

Congratulations! Take a bow!

Browser plugin {new version}

In the fall of 2006, Viewpoints Research Inc provided funding to rewrite the Browser plugin 
using the unix model of small plugin launching headless VM. This XCode project is in the 
Mac OS/vm/npsqueak  directory.  The plugin must interact with a 3.8.16b5 or later Macintosh VM
because of the tight integration of the drawing logic. 
