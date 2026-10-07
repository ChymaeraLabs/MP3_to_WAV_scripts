"""Merge up to three submitted audio files into one mono, loudness-normalized WAV.

Python version of MP3toWAV.ps1. Uses only the standard library (Python 3.7+) and calls
ffmpeg directly, so no pip installs are needed.

Run from the Power Automate Desktop "Run DOS command" action:
    "C:\\Path\\To\\python.exe" "C:\\Apps\\Audio\\data\\MP3toWAV.py" "%Audio1%" "%Audio2%" "%Audio3%" "%campaignName%"

Audio2 and Audio3 may be empty strings. Exits non-zero on failure.
"""
import os
import shutil
import subprocess
import sys

IN_DIR = r"C:\Apps\Audio\infiles"
OUT_DIR = r"C:\Apps\Audio\outfiles"
FFMPEG_FALLBACK = r"C:\Apps\Audio\ffmpeg\ffmpeg.exe"  # adjust if ffmpeg lives elsewhere


def main():
    if len(sys.argv) != 5:
        sys.exit('Usage: MP3toWAV.py <Aud1> <Aud2> <Aud3> <CampaignName>')
    aud1, aud2, aud3, campaign_name = sys.argv[1:]

    ffmpeg = shutil.which("ffmpeg") or FFMPEG_FALLBACK

    # Aud2 and Aud3 may be empty
    files = [os.path.join(IN_DIR, a) for a in (aud1, aud2, aud3) if a]
    if not files:
        sys.exit("No audio files provided.")

    os.makedirs(OUT_DIR, exist_ok=True)

    # One ffmpeg command: convert each input to mono 44.1kHz, join in order, normalize loudness
    cmd = [ffmpeg, "-y"]
    for f in files:
        cmd += ["-i", f]

    n = len(files)
    prep = ";".join("[%d:a]aresample=44100,aformat=channel_layouts=mono[a%d]" % (i, i) for i in range(n))
    labels = "".join("[a%d]" % i for i in range(n))
    flt = "%s;%sconcat=n=%d:v=0:a=1,loudnorm[out]" % (prep, labels, n)

    cmd += ["-filter_complex", flt, "-map", "[out]", os.path.join(OUT_DIR, campaign_name + ".wav")]

    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit("ffmpeg failed with exit code %d" % result.returncode)

    # Only clean up after a successful conversion, and only the files used
    for f in files:
        os.remove(f)


if __name__ == "__main__":
    main()
