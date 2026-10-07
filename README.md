# MP3 to WAV Audio Automation

Converts audio files submitted through a Microsoft Form into a single mono WAV and uploads it to 3CX.

## Workflow

1. **Power Automate (cloud flow)** starts when the MS Form is submitted. The submitted files go to a SharePoint folder, and the file names (file-based scripts) or file contents as base64 (base64 scripts) are passed to Power Automate Desktop.
2. **Power Automate Desktop (PAD)** runs one of the four scripts below.
3. The script joins up to three audio files, in order, into one mono WAV.
4. The WAV is uploaded to 3CX.

## Scripts

All four scripts do the same conversion. There are two input styles, each in PowerShell and Python, so they can be tested against each other.

| Script | Input | Output | Runs with |
|---|---|---|---|
| `MP3toWAV.ps1` | File names | WAV file in `C:\Apps\Audio\outfiles\<campaignName>.wav` | PAD "Run PowerShell script" |
| `MP3toWAV.py` | File names | WAV file in `C:\Apps\Audio\outfiles\<campaignName>.wav` | PAD "Run DOS command" |
| `MP3toWAV-base64.ps1` | Base64 audio | Base64 WAV on stdout | PAD "Run PowerShell script" |
| `MP3toWAV-base64.py` | Base64 audio (stdin) | Base64 WAV on stdout | PAD "Run DOS command" |

All scripts:
- take up to three audio inputs. The second and third may be empty.
- convert each input to mono at 44.1 kHz, join them in order, and apply `loudnorm` loudness normalization.
- fail with an error if ffmpeg fails.

### File-based (`MP3toWAV.ps1`, `MP3toWAV.py`)

Read the files from `C:\Apps\Audio\infiles`, which PAD syncs from the SharePoint folder, so they depend on the sync finishing first. They also take the campaign name, and delete the input files only after a successful conversion.

**PowerShell:** `%Audio1%`, `%Audio2%`, `%Audio3%` and `%campaignName%` in the `param()` block are PAD variables. PAD substitutes them into the script text before it runs. The script relaunches itself in PowerShell 7, because ffmpeg won't run from PAD's PowerShell 5, and passes the values along as parameters.

**Python:** run it from a PAD "Run DOS command" action, using the full path to a Python 3 install. Pass empty values as `""`:

```
"C:\Path\To\python.exe" "C:\Apps\Audio\data\MP3toWAV.py" "%Audio1%" "%Audio2%" "%Audio3%" "%campaignName%"
```

### Base64 (`MP3toWAV-base64.ps1`, `MP3toWAV-base64.py`)

Take the audio content itself, so there's no folder to sync and nothing is read from or written to OneDrive. Each decodes the audio to a temp folder, converts it, returns the merged WAV as one base64 string on stdout, and deletes the temp folder. They don't take a campaign name, so name the file wherever you decode the result.

**PowerShell:** `%Audio1Base64%`, `%Audio2Base64%` and `%Audio3Base64%` in the `param()` block are PAD variables. The PowerShell 5 step pipes them to PowerShell 7 over stdin, because base64 is too long for a command line.

**Python:** reads one base64 audio file per line from stdin, up to three. A command-line argument is too short for base64 and the DOS command action has no stdin field, so have PAD write the values to a local text file outside OneDrive, then:

```
"C:\Path\To\python.exe" "C:\Apps\Audio\data\MP3toWAV-base64.py" < "C:\Apps\Audio\data\in.txt"
```

Things to watch:
- Large strings in PAD variables, script text and captured output may be slow or fail at some size. Test with the largest realistic submission.
- The scripts expect plain base64. Strip any `data:audio/...;base64,` prefix first.
- Don't use PAD's built-in "Run Python script" action. It uses IronPython 2.7 and can't use installed packages.

## Requirements

- ffmpeg, either on PATH or at `C:\Apps\Audio\ffmpeg\ffmpeg.exe`. Edit the fallback path in the script if it lives elsewhere.
- PowerShell 7 at `C:\Program Files\PowerShell\7\pwsh.exe` for the PowerShell scripts.
- Python 3.7+ for the Python scripts. Standard library only.

## Notes

- Power Automate cloud flow and PAD flow configurations aren't stored in this repo.
- Sensitive information has been replaced with `*******`.
