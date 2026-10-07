from pydub import AudioSegment, effects
import ffmpeg, json, os

#Parse JSON
jsonPS1 = 'C:\\Apps\\Audio\\data\\ps1Py.json'
with open(jsonPS1, 'r') as ps1:
    py = json.load(ps1)

#Assign date to Variables, Aud2 and Aud3 may not always contain data
ls = [py['Aud1'],py['Aud2'],py['Aud3']]
cmpgnName = (py['cmpgnName'])

#Grab each file provided and convert to WAV
auds = []
for index in range(len(ls)):
    if ls[index] != '':
        aud=AudioSegment.from_file(f"C:\\*******\\infiles\\{ls[index]}", format=ls[index].split('.')[-1])
        auds.append(aud)

#Convert to Mono and merge converted files and normalize audio
outfile = sum(auds)
outfile = outfile.set_channels(1)
outfile.export(f"C:\\*******\\outfiles\\{cmpgnName}.wav", format="wav")

#Remove files
os.remove(f"C:\\*******\\infiles\\*.mp3")
os.remove(f"C:\\*******\\infiles\\*.wav")
