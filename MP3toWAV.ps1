$psVersion=(Get-Host).Version.Major
if ($psVersion -ne 7) {
    $processInfo=New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName="C:\Program Files\PowerShell\7\pwsh.exe"
    $processInfo.RedirectStandardError=$true
    $processInfo.RedirectStandardOutput=$true
    $processInfo.UseShellExecute=$false
    $processInfo.Arguments=$MyInvocation.MyCommand.Definition
        $process=New-Object System.Diagnostics.Process
        $process.StartInfo=$processInfo
        $process.Start() | Out-Null
        $process.WaitForExit()
        $stdout=$process.StandardOutput.ReadToEnd()
            Write-Host $stdout
}else{
    param($Aud1,$Aud2,$Aud3,$cmpgnName,$scrptPath)
        $Aud1="%Audio1%"
        $Aud2="%Audio2%"
        $Aud3="%Audio3%"
        $cmpgnName="%campaignName%"
        $scrptPath='C:\*******'
#Create JSON
    $JSON=New-Object -TypeName pscustomobject -Property @{
        Aud1=$Aud1
        Aud2=$Aud2
        Aud3=$Aud3
        cmpgnName=$cmpgnName
    }
    $JSON | ConvertTo-Json -Depth 4 | Out-File "$scrptPath\ps1Py.json"
#Launch Python3
    Set-Location -Path $scrptPath
        python MP3-WAV.py
}
