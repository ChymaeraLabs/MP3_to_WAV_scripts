param(
    [string]$Aud1 = "%Audio1%",
    [string]$Aud2 = "%Audio2%",
    [string]$Aud3 = "%Audio3%",
    [string]$CampaignName = "%campaignName%"
)

#Power Automate Desktop runs this in Windows PowerShell 5, which can't run ffmpeg.
#Relaunch in PowerShell 7, passing the values along as parameters (no JSON needed).
IF($PSVersionTable.PSVersion.Major -lt 7){
    $self = IF($PSCommandPath){
                $PSCommandPath
            }else{
                $MyInvocation.MyCommand.Definition
            }
    & "C:\Program Files\PowerShell\7\pwsh.exe" `
    -NoProfile -ExecutionPolicy Bypass -File $self -Aud1 $Aud1 -Aud2 $Aud2 -Aud3 $Aud3 -CampaignName $CampaignName
    exit $LASTEXITCODE
}

$inDir = 'C:\Apps\Audio\infiles'
$outDir = 'C:\Apps\Audio\outfiles'
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
IF(-not $ffmpeg){
    $ffmpeg = 'C:\Apps\Audio\ffmpeg\ffmpeg.exe'   #Adjust if ffmpeg lives elsewhere
}

#Aud2 and Aud3 may be empty
$files = @($Aud1, $Aud2, $Aud3) | Where-Object {$_} | ForEach-Object {Join-Path $inDir $_}
IF(-not $files){
    throw 'No audio files provided.'
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

#Build one ffmpeg command: convert each input to mono 44.1kHz, join in order, normalize loudness
$ffArgs=@('-y')
foreach($f in $files){
    $ffArgs += '-i', $f
}

$n = $files.Count
$prep = (0..($n - 1) | ForEach-Object {"[${_}:a]aresample=44100,aformat=channel_layouts=mono[a$_]"}) -join ';'
$labels = (0..($n - 1) | ForEach-Object {"[a$_]"}) -join ''
$filter = "$prep;${labels}concat=n=${n}:v=0:a=1,loudnorm[out]"

$ffArgs += '-filter_complex', $filter, '-map', '[out]', (Join-Path $outDir "$CampaignName.wav")

& $ffmpeg @ffArgs
IF($LASTEXITCODE -ne 0){
    throw "ffmpeg failed with exit code $LASTEXITCODE"
}

# Only clean up after a successful conversion, and only the files used
$files | Remove-Item -Force
