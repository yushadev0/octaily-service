input_file = "C:\yusag\PROJECTS\OctailyService\data\wordle_tr.txt"
output_file = "C:\yusag\PROJECTS\OctailyService\data\wordle_tr_clean.txt"

mapping = {
    "Î": "İ",
    "Â": "A",
    "Û": "U",
    "î": "i",
    "â": "a",
    "û": "u"
}

with open(input_file, "r", encoding="utf-8") as f:
    text = f.read()

for old, new in mapping.items():
    text = text.replace(old, new)

with open(output_file, "w", encoding="utf-8") as f:
    f.write(text)

print("Dönüşüm tamamlandı.")