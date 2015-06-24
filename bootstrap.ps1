$CYG_MIRROR="http://cygwin.uib.no"
$CYG_CACHE="C:/cygwin/var/cache/setup"
$CYG_ROOT="C:\cygwin"

$Arch = (Get-Process -Id $PID).StartInfo.EnvironmentVariables["PROCESSOR_ARCHITECTURE"];

if ($Arch -eq 'amd64') {
$CYG_ARCH="x86"
$WODI_ARCH= "64"
$MINGW_ARCH= "x86_64"
$MINGW_TOOL_PREFIX="x86_64-w64-mingw32-"
} else {
$CYG_ARCH="x86"
$WODI_ARCH= "32"
$MINGW_ARCH= "i686"
$MINGW_TOOL_PREFIX="i686-w64-mingw32-"
}
   
echo "ARCH $CYG_ARCH"

# -P mingw64-$MINGW_ARCH-gcc-core, mingw64-$MINGW_ARCH-gcc-g++ 

$PACKAGES="-P wget,dos2unix,diffutils,cpio,make,m4,patch  -P mingw64-x86_64-gcc-core, mingw64-x86_64-gcc-g++  -P mingw64-i686-gcc-core, mingw64-i686-gcc-g++  -P zip,git,unzip,autoconf,libncurses-devel,curl,patch"

function Install-Cygwin {
   param ( $TempCygDir="$env:temp\cygInstall" )

   if(!(Test-Path -Path $TempCygDir -PathType Container))
   {
     $null = New-Item -Type Directory -Path $TempCygDir -Force
   }


   wget "http://cygwin.com/setup-$CYG_ARCH.exe" -outfile "$TempCygDir\setup.exe"

   Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -s $CYG_MIRROR -R $CYG_ROOT $PACKAGES"

   echo "CYGWIN INSTALLED !"
}

Install-Cygwin

$BASH="$CYG_ROOT\bin\bash"
& "$BASH" -lc "cygcheck -dc cygwin"
