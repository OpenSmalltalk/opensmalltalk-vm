# Stop on errors
$ErrorActionPreference = 'stop'

# The script name
$scriptFileName = $args[0]
$cygwinRoot = 'c:\cygwin'
$bashExecutable ="$cygwinRoot\bin\bash.exe"

# Create a modified version of the script.
$scriptContent = Get-Content -Path $scriptFileName | Out-String
$modifiedScriptFileName = "$(New-TemporaryFile).sh"
$cygwinModifiedScriptFileName = & "$cygwinRoot\bin\cygpath.exe" "$modifiedScriptFileName"
$cygwinCWD = & "$cygwinRoot\bin\cygpath.exe" (Get-Location)
$modifiedScriptContent = "#!/bin/bash --login
cd $cygwinCWD
export PATH=`"/usr/local/bin:/usr/bin:/cygdrive/c/windows/system32:/cygdrive/c/windows/system32/Wbem`"
set -ex

$scriptContent
".Replace("`r`n","`n")

Out-File -Encoding ASCII -NoNewline -InputObject $modifiedScriptContent $modifiedScriptFileName

# Run the modified script.
& $bashExecutable $cygwinModifiedScriptFileName

# Reflect the last exit code
if ((Test-Path -LiteralPath variable:\LASTEXITCODE)) {
    exit $LASTEXITCODE
}
