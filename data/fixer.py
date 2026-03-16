import json

input_file = "countries.json"
output_file = "countries_updated.json"

def title_tr(text):
    return " ".join(word.capitalize() for word in text.split())

with open(input_file, "r", encoding="utf-8") as f:
    data = json.load(f)

for country in data:
    if "name_tr" in country and isinstance(country["name_tr"], str):
        country["name_tr"] = title_tr(country["name_tr"])

with open(output_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Güncellendi.")