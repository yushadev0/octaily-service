import os

input_file = 'wordle_en.txt'

print("İngilizce kelimeler okunuyor ve standartlaştırılıyor...")

try:
    with open(input_file, 'r', encoding='utf-8') as f:
        # Boşlukları temizle, 5 harfli olanları al ve büyük harfe çevir
        words = [line.strip().upper() for line in f if len(line.strip()) == 5]

    # Mükerrer olanları silmek için 'set' kullanıp tekrar alfabetik sıralıyoruz
    sorted_words = sorted(list(set(words)))

    # Sonucu aynı dosyanın üzerine yazıyoruz
    with open(input_file, 'w', encoding='utf-8') as out_f:
        for w in sorted_words:
            out_f.write(w + '\n')

    print(f"İşlem tamam! Toplam {len(sorted_words)} adet İngilizce kelime '{input_file}' dosyasına başarıyla kaydedildi.")

except FileNotFoundError:
    print(f"Hata: '{input_file}' dosyası bulunamadı. Lütfen dosya adını kontrol et.")