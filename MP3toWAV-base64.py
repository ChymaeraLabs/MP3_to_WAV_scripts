"""Merge up to three base64-encoded audio files into one mono, loudness-normalized WAV.

Python version of MP3toWAV-base64.ps1. Standard library only (Python 3.7+), calls ffmpeg directly.

Input (stdin): up to three lines, one base64 audio file per line. Lines 2 and 3 may be empty.
Output (stdout): the merged WAV as a single base64 string. Exits non-zero on failure.

Base64 is too long for a command-line argument, so it is read from stdin, e.g. from a local text file:
    "C:\\Path\\To\\python.exe" "C:\\Apps\\Audio\\data\\MP3toWAV-base64.py" < "C:\\Apps\\Audio\\data\\in.txt"
"""
import base64
import os
import shutil
import subprocess
import sys
import tempfile

FFMPEG_FALLBACK = r"C:\Apps\Audio\ffmpeg\ffmpeg.exe"  # adjust if ffmpeg lives elsewhere


def main():
    lines = sys.stdin.read().splitlines()[:3]
    b64s = [line.strip() for line in lines if line.strip()]
    if not b64s:
        sys.exit("No audio provided.")

    ffmpeg = shutil.which("ffmpeg") or FFMPEG_FALLBACK

    # Temp files live outside OneDrive and are removed automatically
    with tempfile.TemporaryDirectory() as tmp:
        # Decode each input to a temp file, ffmpeg detects the format from the content
        files = []
        for i, b64 in enumerate(b64s):
            path = os.path.join(tmp, "in%d.bin" % i)
            with open(path, "wb") as fh:
                fh.write(base64.b64decode(b64))
            files.append(path)

        # One ffmpeg command: convert each input to mono 44.1kHz, join in order, normalize loudness
        cmd = [ffmpeg, "-y", "-nostdin", "-loglevel", "error"]
        for f in files:
            cmd += ["-i", f]

        n = len(files)
        prep = ";".join("[%d:a]aresample=44100,aformat=channel_layouts=mono[a%d]" % (i, i) for i in range(n))
        labels = "".join("[a%d]" % i for i in range(n))
        flt = "%s;%sconcat=n=%d:v=0:a=1,loudnorm[out]" % (prep, labels, n)

        out_file = os.path.join(tmp, "out.wav")
        cmd += ["-filter_complex", flt, "-map", "[out]", out_file]

        result = subprocess.run(cmd)
        if result.returncode != 0:
            sys.exit("ffmpeg failed with exit code %d" % result.returncode)

        # Return the merged WAV as base64
        with open(out_file, "rb") as fh:
            sys.stdout.write(base64.b64encode(fh.read()).decode("ascii"))


if __name__ == "__main__":
    main()
