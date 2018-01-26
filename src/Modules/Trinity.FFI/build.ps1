﻿git submodule init
git submodule update --recursive
echo "Setup environment"

foreach($_ in cmd /c " ..\..\..\tools\setenv.bat > `"nul`" 2>&1 && SET") {
	if ($_ -match '^([^=]+)=(.*)') {
		[System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
	}
}

echo "Cleanning caches"
if ($true) {
    Invoke-Command -ScriptBlock {
        $package_loc = (nuget locals global-packages -list)
        $package_loc = $package_loc.Substring(17)
        Get-ChildItem $package_loc -Filter "graphengine*" | Remove-Item -Recurse -Force -ErrorAction Ignore
        Remove-Item -Recurse -Force ..\..\..\bin\lib.win-amd64-3.6 -ErrorAction Ignore
        Remove-Item -Recurse -Force ..\..\..\bin\temp.win-amd64-3.6 -ErrorAction Ignore
        Remove-Item -Recurse -Force ..\..\..\bin\trinity_ffi.*
    } -ErrorAction Ignore
}

function Build($proj, $action, $config)
{
    $cmd = @'
 & dotnet.exe $action /p:Configuration=$config "$proj"
'@
    Invoke-Expression $cmd
}

function MSBuild($proj)
{
    $cmd = @'
 & $env:MSBUILD_EXE "/p:Configuration=Release;Platform=x64" "$proj"
'@
    Invoke-Expression $cmd
}

Build ".\pythonnet\src\runtime\Python.Runtime.15.csproj" -action pack -config ReleaseWinPY3
Move-Item -Path .\pythonnet\src\runtime\bin\Python.Runtime.2.4.0.nupkg -Destination $env:REPO_ROOT\bin -Force
MSBuild .\Trinity.FFI.Native\Trinity.FFI.Native.vcxproj
Build ".\Trinity.FFI.sln" -action pack -config Release