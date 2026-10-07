param(
    [string]$Aud1 = "%Audio1Base64%",
    [string]$Aud2 = "%Audio2Base64%",
    [string]$Aud3 = "%Audio3Base64%"
)

#Accepts up to three base64-encoded audio files and returns ONE base64-encoded mono WAV on stdout.
#Nothing is read from or written to the OneDrive/SharePoint synced folders, temp files are removed when done.
#Aud2 and Aud3 may be empty.

#Power Automate Desktop runs this in Windows PowerShell 5, which can't run ffmpeg.
#Relaunch in PowerShell 7. Base64 is far too long for a command line, so it is piped in over stdin.
IF($PSVersionTable.PSVersion.Major -lt 7){
    $self = IF($PSCommandPath){
                $PSCommandPath
            }else{
                $MyInvocation.MyCommand.Definition
            }
    ($Aud1, $Aud2, $Aud3 -join "`n") | & "C:\Program Files\PowerShell\7\pwsh.exe" `
    -NoProfile -ExecutionPolicy Bypass -File $self
    exit $LASTEXITCODE
}

#PowerShell 7: read the three base64 values from stdin
$lines = ([Console]::In.ReadToEnd()) -split "\r?\n"
$b64s = @($lines | Select-Object -First 3) | ForEach-Object {$_.Trim()} | Where-Object {$_}
IF(-not $b64s){
    throw 'No audio provided.'
}

$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
IF(-not $ffmpeg){
    $ffmpeg = 'C:\Apps\Audio\ffmpeg\ffmpeg.exe'   #Adjust if ffmpeg lives elsewhere
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try{
    #Decode each input to a temp file, ffmpeg detects the format from the content
    $files = @()
    $i = 0
    foreach($b64 in $b64s){
        $path = Join-Path $tmp "in$i.bin"
        [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b64))
        $files += $path
        $i++
    }

    #Build one ffmpeg command: convert each input to mono 44.1kHz, join in order, normalize loudness
    $ffArgs = @('-y', '-nostdin', '-loglevel', 'error')
    foreach($f in $files){
        $ffArgs += '-i', $f
    }

    $n = $files.Count
    $prep = (0..($n - 1) | ForEach-Object {"[${_}:a]aresample=44100,aformat=channel_layouts=mono[a$_]"}) -join ';'
    $labels = (0..($n - 1) | ForEach-Object {"[a$_]"}) -join ''
    $filter = "$prep;${labels}concat=n=${n}:v=0:a=1,loudnorm[out]"

    $outFile = Join-Path $tmp 'out.wav'
    $ffArgs += '-filter_complex', $filter, '-map', '[out]', $outFile

    & $ffmpeg @ffArgs
    IF($LASTEXITCODE -ne 0){
        throw "ffmpeg failed with exit code $LASTEXITCODE"
    }

    #Return the merged WAV as base64
    [Convert]::ToBase64String([IO.File]::ReadAllBytes($outFile))
}finally{
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
