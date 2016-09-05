#!/bin/bash -ex
. ./envvars.sh

# Author tty.
# 2014-05-01
# This script downloads and configur
#Overview of script flow assuming version 4.5 
#  parse options
#  case statement on -v  option
#  clean_source_tree  (not used until migration to cmake is complete and GNU-B-GONE
#  create_cmake_source_tree
#  get_four_five
#  launch_and_configure_four_five
#  run_four_five
#
#  4.6 follows same flow.
#  adding new versions should be evident



#begin function declarations

show_help() {
cat << EOF
Usage: ${0##*/} [-b]  [-h] [-s VERSION] [-t TRUNK]  [-v VERSION] 
Download and configure a Squeak image configured for Cog and/or Standard VM building. load either stable or trunk classes. 

    -b          Both Cog Interpreter configuration  and Standard Interpreter configuration on latest stable branch 
    -c VERSION  Cog Interpreter configuration on squeak VERSION
    -h          display this help and exit
    -s VERSION  Standard Interpreter configuration on squeak VERSION 
    -t          Monticello source is trunk (2014-05-05 only 4.5 supported  and is ignored otherwise)



Example:  ./buildsqueakcmakeimage -b           (configure BOTH Squeak 4.6 for CMake VMMaker.oscog and  configure an additional Standard Intepreter VMMaker on 4.6) 
          ./buildsqueakcmakeimage -c 4.5       (configure Squeak 4.5 for CMake VMMaker.oscog) 
          ./buildsqueakcmakeimage -c 4.5 -t    (configure Squeak 4.5 for CMake VMMaker.oscog. Monticello source is trunk) 
          ./buildsqueakcmakeimage -c 4.6       (configure Squeak 4.6 for CMake VMMaker.oscog) 
          ./buildsqueakcmakeimage -s 4.5       (configure Squeak 4.5 for CMake VMMaker) 
          ./buildsqueakcmakeimage -s 4.6       (configure Squeak 4.6 for CMake VMMaker) 
          ./buildsqueakcmakeimage -c 4.6 -s    (same as cmakeify -b )

SEE: README.buildsqueakcmakeimage for details of this script.
EOF

}                

check_required(){
  wget --help >/dev/null || (echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2; exit 1)
  unzip --help >/dev/null || (echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2; exit 1)
  rsync --help >/dev/null || (echo 'could not find rsync.  you can find instructions on how to install it on google.' 1>&2; exit 1)
  sed --help >/dev/null || (echo 'could not find sed.  you can find instructions on how to install it on google.' 1>&2; exit 1)
}

#create a parallel build tree for cmake
create_cmake_source_tree(){

    echo $1
    cd $1
    cp -Rv  cygwinbuild cmake_cygwinbuild 
    cp -Rv  macbuild  cmake_macbuild 
    cp -Rv  nsbuild    cmake_nsbuild   
    cp -Rv  nscogbuild  cmake_nscogbuild 
    cp -Rv  nsspurcogbuild   cmake_nsspurcogbuild 
    cp -Rv  nsspurstackbuild  cmake_nsspurstackbuild 
    cp -Rv  sistamacbuild  cmake_sistamacbuild 
    cp -Rv  spurcogbuild   cmake_spurcogbuild  
    cp -Rv  spursistamacbuild  cmake_spursistamacbuild 
    cp -Rv  spurstackbuild cmake_spurstackbuild 
    cp -Rv  stackbuild  cmake_stackbuild  
    cp -Rv  unixbuild   cmake_unixbuild

    find ./cmake_*  -type f -name "mvm" -exec rm -f {} \;
    find ./cmake_*  -type f -name "HowToBuild" -exec rm -f {} \;

    cd -
}

clean_source_tree(){
echo $1
    cd $1

    find ./ -type f -name "ChangeLog" -exec rm -f {} \;
    find ./ -type f -name "Makefile*" -exec rm -f {} \;
    find ./ -type f -name "*README *" -exec rm -f {} \;
    find ./ -type f -name "make*" -exec rm -f {} \;
    find ./ -type f -name "mk*" -exec rm -f {} \;
    find ./ -type f -name "mvm" -exec rm -f {} \;
    find ./ -type f -name "plugins.int" -exec rm -f {} \;
    find ./ -type f -name "plugins.ext" -exec rm -f {} \;
    find ./ -type f -name "examplePlugins.*" -exec rm -f {} \;
    find ./ -type f -name "HowToBuild" -exec rm -f {} \;

    find ./ -type f -name "*.bat" -exec rm -f {} \;
    find ./ -type f -name "*.~" -exec rm -f {} \;
    find ./ -type f -name "*.config" -exec rm -f {} \;
    find ./ -type f -name "*.gz" -exec rm -f {} \;
    find ./ -type f -name "*.in" -exec rm -f {} \;
    find ./ -type f -name "*.lproj" -exec rm -f {} \;
    find ./ -type f -name "*.manifest" -exec rm -f {} \;
    find ./ -type f -name "*.pch" -exec rm -f {} \;
    find ./ -type f -name "*.rc" -exec rm -f {} \;
    find ./ -type f \( -iname "*.sh" ! -iname "buildsqueaktrunkimage.sh" \)  -exec rm -f {} \;  #rm .sh files except this one! (:
    find ./ -type d -name "*.xcodeproj" -exec rm -Rf {} \;
    find ./ -type d -name "*.lproj" -exec rm -Rf {} \;
echo $1
    cd -
}

fourty_two(){
echo 'Answer to the Ultimate Question of Life, the Universe, and Everything'
exit
}


get_four_five(){

  cd  $COGINSTALLDIRECTORY

  check_required

  ./getsqueak45.sh

  cp -p $SQUEAK45.image              $SQUEAK45RESOURCES/CogVMMaker.image
  cp -p $SQUEAK45.changes            $SQUEAK45RESOURCES/CogVMMaker.changes

  cd -
}

launch_and_configure_four_five(){  #copy-n-paste-n-mangle from Bert's squeak.sh

  case $OS in
    BSD)	SQUEAK45VM="$COGINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    Darwin)	SQUEAK45VM="$COGINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    SOLARIS*)	SQUEAK45VM="$COGINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    CYGWIN*)	SQUEAK45VM="$COGINSTALLDIRECTORY/$SQUEAK45APP/SqueakConsole.exe";;
    Linux)	if [ "$CPU" = x86_64 ]; then
		  CPU=i686
		  echo Running 32-bit Squeak on a 64-bit System. Hope the 32-bit runtime libraries are installed ... 
		 fi
   	       SQUEAK45VM="$COGINSTALLDIRECTORY/$SQUEAK45APP/Contents/$OS-$CPU/bin/squeak";;
  *)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
  esac

  if [ "$TRUNK" = true ]; then
     SCRIPT="$APP/BuildSqueak45TrunkCMakeVMMakerImage.st"
  else
     SCRIPT="$APP/BuildSqueak45CMakeVMMakerImage.st" 
  fi

  if [ "$CPU" = x86_64 ] ; then
	  CPU=i686
  fi

  showerror() {
      if [ -n "$DISPLAY" -a -x "`which kdialog 2>/dev/null`" ]; then
	  kdialog --error "$1"
      elif [ -n "$DISPLAY" -a -x "`which zenity 2>/dev/null`" ]; then
	  zenity --error --text "$1"
      else
	  dialog --msgbox "$1" 0 0
      fi
  }

  if [ ! -x "$SQUEAK45VM" ] ; then
      if [ ! -r "$SQUEAK45VM" ] ; then
	  showerror "This Squeak version does not support $OS-$CPU"
      else
	  showerror "Squeak does not have permissions to execute"
      fi
  fi


  rsync -av --progress ../*  $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES/oscogvm  --exclude $PWD                   #copy Cog source tree (minus this directory) to standard dir and remove GNU build artefacts

  cd $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES
    ln -s oscogvm/platforms platforms                         #<--needed for VMMakerTool
  cd -

#    clean_source_tree $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES/oscogvm                       
  create_cmake_source_tree $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES/oscogvm                       

  cp $COGINSTALLDIRECTORY/$SQUEAK45APP/squeak.sh $COGINSTALLDIRECTORY/$SQUEAK45APP/squeakCogVMMaker.sh    #create a shell script that launches our CogVMMaker.image
  sed -i -e "s/$SQUEAK45IMAGE/$COGIMAGE/g" $COGINSTALLDIRECTORY/$SQUEAK45APP/squeakCogVMMaker.sh   
  

  cp -p *.text       $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES  #Workspaces with helpful text
  cp -p *.config     $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES  #VMMakerTool configuration files
  cp -p *.st         $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES  #Smalltalk 

  "$SQUEAK45VM" "$COGINSTALLDIRECTORY/$SQUEAK45RESOURCES/$COGIMAGE" "$SCRIPT"
  
}

get_four_five_standard_vm(){


  cd    $STANDARDINSTALLDIRECTORY

  check_required
  ./getsqueak45.sh

  cp -p $SQUEAK45.image              $SQUEAK45RESOURCES/StandardVMMaker.image
  cp -p $SQUEAK45.changes            $SQUEAK45RESOURCES/StandardVMMaker.changes

#  cp -R ~/trunk $SQUEAK45RESOURCES   #<--script development timesaver. use cp instead of svn
  svn co http://squeakvm.org/svn/squeak/trunk $SQUEAK45RESOURCES/trunk

  if [ -h  $SQUEAK45RESOURCES/platforms ]; then
     rm -f $SQUEAK45RESOURCES/platforms 
  fi
  cd $SQUEAK45RESOURCES
   ln -s trunk/platforms platforms                         #<--needed for VMMakerTool
   mkdir build
  cd -

  cd ../

}

launch_and_configure_four_five_standard(){  
#echo 'http://wiki.squeak.org/squeak/6177'
  case $OS in
    BSD)	SQUEAK45VM="$STANDARDINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    Darwin)	SQUEAK45VM="$STANDARDINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    SOLARIS*)	SQUEAK45VM="$STANDARDINSTALLDIRECTORY/$SQUEAK45APP/Contents/MacOS/Squeak";;
    CYGWIN*)	SQUEAK45VM="$STANDARDINSTALLDIRECTORY/$SQUEAK45APP/SqueakConsole.exe";;
    Linux)	if [ "$CPU" = x86_64 ]; then
		  CPU=i686
		  echo Running 32-bit Squeak on a 64-bit System. Hope the 32-bit runtime libraries are installed ... 
		 fi
   	       SQUEAK45VM="$STANDARDINSTALLDIRECTORY/$SQUEAK45APP/Contents/$OS-$CPU/bin/squeak";;
  *)	echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
  esac
  SCRIPT="$APP/BuildSqueakStandardVMMakerImage.st" 


  cp $STANDARDINSTALLDIRECTORY/$SQUEAK45APP/squeak.sh $STANDARDINSTALLDIRECTORY/$SQUEAK45APP/squeakStandardVMMaker.sh    #create a shell script that launches our CogVMMaker.image
  sed -i -e "s/$SQUEAK45IMAGE/$STANDARDIMAGE/g" $STANDARDINSTALLDIRECTORY/$SQUEAK45APP/squeakStandardVMMaker.sh   

  rm -f  $STANDARDINSTALLDIRECTORY/$SQUEAK45APP/squeakCogVMMaker.sh    #if we copied Squeak from the cogVMMaker directory, remove the cog launch script


 cp -p *.text                      $STANDARDINSTALLDIRECTORY/$SQUEAK45RESOURCES  #Workspaces with helpful text
 cp -p *.config                    $STANDARDINSTALLDIRECTORY/$SQUEAK45RESOURCES  #VMMakerTool configuration files
 cp -p BuildSqueakStandardVMMakerImage.st $STANDARDINSTALLDIRECTORY/$SQUEAK45RESOURCES  #Smalltalk 

 "$SQUEAK45VM" "$STANDARDINSTALLDIRECTORY/$SQUEAK45RESOURCES/$STANDARDIMAGE" "$SCRIPT"

}
## 4.6 is not an all-in-one as of 2014-04-30 therefore, we need a cog vm 
get_four_six(){

  cd $COGINSTALLDIRECTORY

  check_required

  case $OS in     #TODO windows mac etc
    Linux)	

                wget -c http://www.mirandabanda.org/files/Cog/VM/VM.r2776/coglinux-13.33.2776.tgz  #TODO <--do I need to generalize this?
                tar -xf coglinux-13.33.2776.tgz
                rm -f   coglinux-13.33.2776.tgz

                wget -c ftp.squeak.org/4.6alpha/$SQUEAK46ZIP 
                unzip $SQUEAK46ZIP  -d $COGLINUX
                rm $SQUEAK46ZIP 

		cd $COGLINUX
                cp -p $SQUEAK46.image    CogVMMaker.image
                cp -p $SQUEAK46.changes  CogVMMaker.changes
                 
                cd ../

                ;;
         *)	echo "No Cog found.  bailing out." 1>&2; exit 2
  esac

  cd ../
}


launch_and_configure_four_six(){

  cp -p BuildSqueak46CMake* $COGINSTALLDIRECTORY/coglinux
  cp -p *.text              $COGINSTALLDIRECTORY/coglinux
  cp -p *.config            $COGINSTALLDIRECTORY/coglinux

  rsync -avq --progress ../*  $COGINSTALLDIRECTORY/coglinux/oscogvm  --exclude $PWD                  #copy Cog source tree (minus this directory) to standard dir and remove GNU build artefacts

#  clean_source_tree $COGINSTALLDIRECTORY/$SQUEAK45RESOURCES/oscogvm
  create_cmake_source_tree $COGINSTALLDIRECTORY/$COGLINUX/oscogvm


  cd $COGINSTALLDIRECTORY/$COGLINUX
  ln -s  oscogvm/platforms platforms   #<--needed for VMMakerTool
  ./squeak CogVMMaker.image BuildSqueak46CMakeVMMakerImage.st
  cd -

  cd ../
} 


get_four_six_standard_vm(){



  cd    $STANDARDINSTALLDIRECTORY

  check_required

  if [ -d   ../$COGINSTALLDIRECTORY ]; then     #   if it exists copy the cog stuff over for reuse and  clean it up otherwise downaload via svn
    cp -R   ../$COGINSTALLDIRECTORY/$COGLINUX ./
    rm -f   $COGLINUX/CogVMMaker.*
    rm -f   $COGLINUX/squeakCogVMMaker.sh
    rm -Rf   $COGLINUX/oscogvm
  else
    wget -c http://www.mirandabanda.org/files/Cog/VM/VM.r2776/coglinux-13.33.2776.tgz  #TODO <--do I need to generalize this?
    tar -xf coglinux-13.33.2776.tgz
    rm -f   coglinux-13.33.2776.tgz

    wget -c ftp.squeak.org/4.6alpha/$SQUEAK46ZIP 
    unzip $SQUEAK46ZIP  -d $COGLINUX
    rm $SQUEAK46ZIP 

    cd $COGLINUX
      cp -p $SQUEAK46.image    StandardVMMaker.image
      cp -p $SQUEAK46.changes  StandardVMMaker.changes
    cd ../
  fi


#   cp -R ~/trunk $COGLINUX   #<--script development timesaver. use cp instead of svn
   svn co http://squeakvm.org/svn/squeak/trunk $COGLINUX/trunk

   if [ -h  $COGLINUX/platforms ]; then
      rm -f $COGLINUX/platforms 
   fi
   cd $COGLINUX
    ln -s trunk/platforms platforms                         #<--needed for VMMakerTool
    mkdir build
   cd -

  cd ../

}

launch_and_configure_four_six_standard(){  
#echo 'http://wiki.squeak.org/squeak/6177'


  cp -p BuildSqueakStandardVMMakerImage.st  $STANDARDINSTALLDIRECTORY/$COGLINUX
  cp -p *.text         $STANDARDINSTALLDIRECTORY/$COGLINUX
  cp -p *.config       $STANDARDINSTALLDIRECTORY/$COGLINUX
  cd $STANDARDINSTALLDIRECTORY/$COGLINUX
  ./squeak StandardVMMaker.image BuildSqueakStandardVMMakerImage.st
  cd -
}


#end function declarations
#begin script proper

# initialize variables:

#Flow Control Variables
APP=`dirname "$0"`
APP=`cd "$APP";pwd`
OS=`uname -s`
CPU=`uname -m`
COG=false                  #include cog configuration
STANDARD=false             #include standard configuration
TRUNK=false                #build from trunk
VERSION=4.6
NO_ARGS=0 
E_OPTERROR=85

#Squeak 4.5 specific variables
SQUEAK45IMAGE="Squeak4.5-13680.image"
SQUEAK45VM="DETERMINED IN launch_and_configure_four_five()"

#Squeak 4.6 specific variables
SQUEAK46=Squeak4.6-13700
SQUEAK46ZIP=$SQUEAK46.zip
COGLINUX=coglinux

#Squeak Common variables 
COGIMAGE="CogVMMaker.image"                
STANDARDIMAGE="StandardVMMaker.image"           
COGINSTALLDIRECTORY="cogVMMaker"                #Cog buildsqueakcmakeimage end result lives here
STANDARDINSTALLDIRECTORY="standardVMMaker"      #Standard Intepreter buildsqueakcmakeimage end result lives here



if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args
then
  show_help
  exit $E_OPTERROR          # Exit and explain usage.
fi  

#parse options
OPTIND=1 
while getopts "bc:hs:t" opt; do
    case "$opt" in
	b)  VERSION=4.5   #latest stable branch
	    COG=true
            STANDARD=true
	    TRUNK=false
	    ;;
        c)  VERSION=$OPTARG
            COG=true
            ;;
        h)
            show_help
            exit 0
            ;;
        s)  VERSION=$OPTARG
            STANDARD=true
            ;;

        t)  TRUNK=true
            ;;

        '?')
1            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.




##download squeak and launch it with appropriate smalltalk script.
case "$VERSION" in 
    4.5)
       if [ "$COG" = true ]; then
          mkdir $COGINSTALLDIRECTORY
          [ "$TRUNK" == true ] && printf 'Loading Squeak version %s and configuring from trunk\n' "$VERSION"  || printf 'Loading Squeak version %s\n' "$VERSION"
          [ "$TRUNK" == true ] && (get_four_five $TRUNK) || (get_four_five)
          launch_and_configure_four_five $TRUNK
  	  printf  'to run CogVMMaker:  cd %s; ./squeakCogVMMaker.sh\n'  "$COGINSTALLDIRECTORY/$SQUEAK45APP"
       fi

       if [ "$STANDARD" = true ]; then
          mkdir $STANDARDINSTALLDIRECTORY
          get_four_five_standard_vm
          launch_and_configure_four_five_standard
   	  printf  'to run StandardVMMaker:  cd %s; ./squeakStandardVMMaker.sh\n'  "$STANDARDINSTALLDIRECTORY/$SQUEAK45APP"
       fi

       [ "$TRUNK" == true ] && (echo 'Squeak 4.5 Trunk installation and configuration complete. ';) || (echo 'Squeak 4.5 installation and configuration complete. ';)
	;;
    4.6)
       if [ "$COG" = true ]; then
          mkdir $COGINSTALLDIRECTORY
          printf 'Loading Squeak version %s\n' "$VERSION"
          get_four_six
          launch_and_configure_four_six

    	  printf 'to run CogVMMaker:  cd %s; squeak CogVMMaker.image' "$COGINSTALLDIRECTORY/coglinux"
       fi
       if [ "$STANDARD" = true ]; then
          mkdir $STANDARDINSTALLDIRECTORY
          get_four_six_standard_vm
          launch_and_configure_four_six_standard
 	  printf 'to run StandardVMMaker:  cd %s; squeak StandardVMMaker.image' "$STANDARDINSTALLDIRECTORY/coglinux"  
       fi
          echo 'Squeak 4.6 installation and configuration complete. ';
	  exit
	;;

    42)
        fourty_two;
	;;
     *) echo 'version $VERSION not supported. Try 4.5 or 4.6'
        exit 2
        ;;
  esac


exit
