# Stop on errors
$ErrorActionPreference = 'stop'

# Parse some arguments and set some variables.
$installerName = $args[0]
$cygwinArch = $args[1]
$installerURL = "http://cygwin.com/$installerName"
$cygwinRoot = 'c:\cygwin'
$cygwinMirror ="http://cygwin.mirror.constant.com"

# Download the cygwin installer.
echo "Downloading the Cygwin installer from $installerURL"
Invoke-WebRequest -UseBasicParsing -URI "$installerURL" -OutFile "$installerName"

# Install cygwin and the required packages.
echo "Installing Cygwin packages"
& ".\$installerName" -dgnqNO -R "$cygwinRoot" -s "$cygwinMirror" -l "$cygwinRoot\var\cache\setup" `
    -P make `
    -P cmake `
    -P zip `
    -P mingw64-$cygwinArch-clang `
    -P unzip `
    -P wget `
    -P git `
    -P patch | Out-Null

echo "Cygwin installed under $cygwinRoot"
