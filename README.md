# MP3 to WAV Audio Automation

Converts audio files submitted through a Microsoft Form into a single mono WAV and uploads it to 3CX.

## Workflow

1. **Power Automate (cloud flow)** starts when the MS Form is submitted. The submitted files go to a SharePoint folder, and the file names are parsed from the form's JSON and passed to Power Automate Desktop.
2. **Power Automate Desktop (PAD)** syncs the SharePoint folder to `C:\Apps\Audio\infiles` and runs one of the scripts below.
3. The script joins up to three audio files, in order, into one mono WAV and writes it to `C:\Apps\Audio\outfiles\<campaignName>.wav`.
4. The WAV is uploaded to 3CX.

## Scripts

Both scripts do the same job. Use whichever runs reliably in your environment.

| Script | Runs with | Notes |
|---|---|---|
| `MP3toWAV.ps1` | PAD "Run PowerShell script" | Relaunches itself in PowerShell 7, because ffmpeg won't run from PAD's PowerShell 5, then calls ffmpeg directly. |
| `MP3toWAV.py` | PAD "Run DOS command" | Python 3.7+, standard library only. Calls ffmpeg directly. |

Both scripts:
- take four values: Audio1, Audio2, Audio3 and the campaign name. Audio2 and Audio3 may be empty.
- convert each input to mono at 44.1 kHz, join them in order, and apply `loudnorm` loudness normalization.
- delete the input files only after a successful conversion, and fail with an error if ffmpeg fails.

### PowerShell

`%Audio1%`, `%Audio2%`, `%Audio3%` and `%campaignName%` in the `param()` block are PAD variables. PAD substitutes them into the script text before it runs. The script passes them to PowerShell 7 as parameters, so no intermediate JSON file is needed.

### Python

Run it from a PAD "Run DOS command" action, using the full path to a Python 3 install:

```
"C:\Path\To\python.exe" "C:\Apps\Audio\data\MP3toWAV.py" "%Audio1%" "%Audio2%" "%Audio3%" "%campaignName%"
```

Pass empty values as `""`. Don't use PAD's built-in "Run Python script" action. It uses IronPython 2.7 and can't use installed packages.

## Requirements

- ffmpeg, either on PATH or at `C:\Apps\Audio\ffmpeg\ffmpeg.exe`. Edit the fallback path in the script if it lives elsewhere.
- PowerShell 7 at `C:\Program Files\PowerShell\7\pwsh.exe` for the PowerShell script.
- Python 3.7+ for the Python script.

## Notes

- Power Automate cloud flow and PAD flow configurations aren't stored in this repo.
- Sensitive information has been replaced with `*******`.
