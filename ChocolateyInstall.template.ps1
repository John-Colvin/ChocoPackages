$packageName = ''
$fileType = ''
$silentArgs = ''
$url = ''
$url64bit = ''
$version = ''

Install-ChocolateyPackage $packageName $fileType $silentArgs $url $url64bit

$chocTempDir = Join-Path $env:TEMP "chocolatey"
$unzipLocation = Join-Path $chocTempDir "$packageName"
$file = Join-Path $unzipLocation "$($packageName)Install.zip"
$toolsDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$contentDir = $($toolsDir | Split-Path | Join-Path -ChildPath "content")

$binRoot = "$env:systemdrive\"
### Using an environment variable to to define the bin root until we implement YAML configuration ###
if($env:chocolatey_bin_root -ne $null){$binRoot = join-path $env:systemdrive $env:chocolatey_bin_root}

#Install-ChocolateyZipPackage $packageName $url $unzipLocation

# Add a symlink/batch file to the path
$binDir = join-path $env:chocolateyinstall 'bin'
$binary = $packageName
$exePath = "$binary\$binary.exe"
$useSymLinks = $false # You can set this value to $true if the executable does not depend on external dlls

# If the program installs somewhere other than "Program Files"
# set the $programFiles variable accordingly
$is64bit = (Get-WmiObject Win32_Processor).AddressWidth -eq 64
$programFiles = $env:programfiles
if ($is64bit) {
    if($url64bit){
        $programFiles = $env:ProgramW6432}
    else{
        $programFiles = ${env:ProgramFiles(x86)}
        }
}

try {
    $executable = join-path $programFiles $exePath
    $fsObject = New-Object -ComObject Scripting.FileSystemObject
    $executable = $fsObject.GetFile("$executable").ShortPath

    $symLinkName = Join-Path $binDir "$binary.exe"
    $batchFileName = Join-Path $binDir "$binary.bat"

    # delete the batch file if it exists.
    if(Test-Path $batchFileName){
      Remove-Item "$batchFileName"}

    if($useSymLinks -and ((gwmi win32_operatingSystem).version -ge 6)){
        Start-ChocolateyProcessAsAdmin "if(Test-Path $symLinkName){Remove-Item $symLinkName}; $env:comspec /c mklink /H $symLinkName $executable"
      }
    else{
    "@echo off
    start $executable %*" | Out-File $batchFileName -encoding ASCII
        }
    Write-ChocolateySuccess $packageName
} catch {
  Write-ChocolateyFailure $packageName "$($_.Exception.Message)"
  throw
}
