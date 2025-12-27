# borsatakip

Sage West - Borsa Takip Uygulaması
Sage West, yatırımcıların finansal piyasaları anlık olarak izleyebilmeleri ve kendi portföylerini yönetebilmeleri amacıyla geliştirilmiş kapsamlı bir mobil finansal asistan uygulamasıdır. Kullanıcılar Borsa İstanbul verilerine, döviz kurlarına ve güncel ekonomi haberlerine tek bir platform üzerinden erişim sağlayabilmektedir.

Temel Ozellikler
Canlı Piyasa Verileri: Yahoo Finance API entegrasyonu aracılığıyla Borsa İstanbul (BIST) hisse senetleri, döviz pariteleri ve emtia fiyatları anlık olarak takip edilmektedir.

Portfolyo Yonetimi: Kullanıcılar sahip oldukları varlıkları sembol, miktar ve maliyet bilgileriyle sistemlerine ekleyebilmekte; toplam kâr ve zarar durumlarını anlık fiyatlar üzerinden görüntüleyebilmektedir.

Ekonomi Haberleri: CNN Türk Ekonomi servisinden çekilen güncel haber akışı ile piyasalardaki son gelişmeler gerçek zamanlı olarak takip edilebilmektedir.

Grafik ve Analiz: Hisse senetleri ve döviz kurları için geçmişe dönük veriler görselleştirilerek teknik analiz imkanı sunulmaktadır.

Kimlik Dogrulama: Firebase Authentication kullanılarak güvenli giriş, kayıt olma ve şifre sıfırlama süreçleri profesyonel standartlarda yönetilmektedir.

Kullanılan Teknolojiler ve Araclar
Framework: Flutter

Programlama Dili: Dart

Veritabani ve Sunucu: Firebase (Firestore Cloud & Authentication)

Durum Yonetimi (State Management): Provider

Veri Kaynakları: Yahoo Finance API (Piyasa Verileri) ve CNN Türk (Ekonomi Haberleri)

Grafik Kutuphanesi: FL Chart

Proje Yapısı ve Mimari
Sage West, kodun okunabilirliğini ve sürdürülebilirliğini artırmak adına katmanlı (layered) bir mimari ile geliştirilmiştir:

Models: Veri yapılarını ve sınıfları içerir.

Services: API isteklerini, Firebase işlemlerini ve CNN Türk üzerinden haber çekme mantığını yönetir.

Providers: Uygulama genelindeki durum yönetimini (state management) sağlar.

Widgets: Tekrar kullanılabilir arayüz bileşenlerini barındırır.

Pages: Uygulamanın temel ekranlarını (Giriş, Portföy, Analiz, Haberler) oluşturur.

## Uygulama Ekran Goruntuleri

### Portfoy Yonetimi
![Portfoy Sayfasi](screenshots/Portföy.png)

### Piyasa Analizi ve Grafikler
![Analiz Sayfasi](screenshots/Analiz.png)

### Sage West Yapay Zeka Destegi
![Yapay Zeka](screenshots/ai.png)

### CNN Turk Ekonomi Haberleri
![Haberler Sayfasi](screenshots/Haberler.png)

### Kullanici Profili
![Profil Sayfasi](screenshots/Profil.png)