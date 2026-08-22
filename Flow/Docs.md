TITEN: Sistem Peringatan Tanah Longsor dan Kebakaran Hutan  
TRILOGY 
MUHAMMAD ZAHIR SIRAJ 
ZABDAN HARJATI PURNOMO 
MUHAMMAD RASYA AL FARIDZI 
SMK BUDI LUHUR 
KOTA TANGERANG 
2026 
1. DAFTAR ISI 
DAFTAR ISI 
2. DESKRIPSI SINGKAT IDE 
3. LATAR BELAKANG 
4. TUJUAN DAN MANFAAT IDE 
4.1. Tujuan 
4.2. Manfaat 
5. BATASAN DAN SASARAN PENGGUNA 
5.1. Batasan 
5.2. Sasaran Pengguna 
6. ANALISIS 
6.1. Alat dan Bahan yang digunakan 
6.2. Konsep yang diterapkan 
6.3. [Sub-bab lain] 
7. IMPLEMENTASI DAN CARA KERJA 
8. DESAIN 
8.1. Arsitektur Perangkat Lunak 
8.2. Arsitektur Perangkat Keras 
8.3. Representasi User Interface 
8.4. [Sub-bab lain] 
9. DAFTAR PUSTAKA 
10. LAMPIRAN 
ii 
1 
2 
3 
3 
3 
4 
4 
4 
5 
5 
7 
8 
9 
11 
11 
12 
14 
15 
16 
17 
2 
2. DESKRIPSI SINGKAT IDE 
Bencana tanah longsor dan kebakaran hutan sering terjadi mendadak, 
membuat warga kurang persiapan karena peringatan yang terlambat. Berangkat 
dari masalah ini, kami merancang inovasi "Sistem Deteksi Dini Longsor dan 
Kebakaran Hutan Berbasis IoT". Inovasi ini mampu siaga selama 24 jam penuh 
pada lokasi rawan, tangguh, dan sangat hemat energi. 
Sistem ini mandiri karena ditenagai panel surya yang dipadukan dengan 
baterai pengisian otomatis. Kita tidak perlu repot menarik kabel listrik panjang 
menuju tebing atau hutan. Supaya konsumsi daya sangat efisien, mikrokontroler 
alat diatur dalam mode deep sleep. Sistem hanya akan bangun secara rutin setiap 
enam jam sekali untuk mengecek dan mengirim status tanah terkini. 
Namun, alat ini dirancang amat pintar dengan fitur bangun otomatis. 
Walaupun berada dalam mode tidur, jika terjadi anomali seperti tanah mendadak 
miring, muncul getaran, atau kelembaban berubah drastis, alat akan langsung 
aktif. Perangkat membawa berbagai sensor komplit: kemiringan tanah, 
kelembaban tanah, getaran, dan kelembaban udara. Kombinasi sensor udara inilah 
yang membuatnya menjadi multifungsi, bisa mendeteksi longsor sekaligus 
memantau indikasi awal kebakaran hutan. 
Saat bahaya terdeteksi, peringatan dini langsung dieksekusi lewat dua jalur 
utama. Pertama, peringatan lokal: buzzer bising beserta lampu LED strip darurat 
akan langsung menyala pada lokasi untuk memperingatkan warga sekitar. Kedua, 
peringatan jarak jauh: alat segera mengirimkan sinyal darurat menggunakan 
modul LoRa. LoRa amat ideal karena jangkauannya jauh dan mampu menembus 
rintangan alam meskipun area itu tidak memiliki sinyal seluler. 
Sinyal darurat LoRa tersebut selanjutnya diterima oleh IoT Gateway di 
area pemukiman terdekat. Dari gateway, data akan segera diteruskan melalui WiFi 
supaya notifikasi bahaya dapat diakses langsung lewat aplikasi ponsel. 
1 
3. LATAR BELAKANG 
Awal mula kami mendapatkan ide rancangan ini adalah ketika melihat 
tema utama yang diangkat, yaitu "Long Life Legacy: Empowering Smart Cities for 
a Sustainable Urban Future". Dari beberapa opsi yang ada, perhatian kami 
langsung tertuju untuk memilih subtema "Climate Disaster Technology". Alasan 
kami cukup sederhana namun fundamental: secanggih apapun infrastruktur 
sebuah "Kota Pintar" (Smart City), keberlanjutannya akan selalu terhambat dan 
terancam lumpuh jika tidak memiliki sistem mitigasi yang baik terhadap bencana 
alam. Kota yang cerdas harus memiliki pertahanan yang cerdas pula terhadap 
ancaman iklim. 
Berangkat dari pemikiran tersebut, kami mulai melakukan pencarian dan 
riset mengenai masalah bencana alam di sekitar kita. Kami menyadari bahwa 
tanah longsor dan kebakaran hutan adalah dua ancaman yang sangat merusak, 
datangnya tiba-tiba, dan memakan banyak korban jiwa maupun materi. Kami pun 
memutuskan untuk membuat sebuah alat deteksi dini yang bisa ditempatkan 
langsung di titik-titik rawan, seperti ditanam di lereng atau tebing curam untuk 
mendeteksi longsor, serta ditempatkan di dalam kawasan hutan untuk mendeteksi 
anomali suhu dan asap kebakaran. 
2 
4. TUJUAN DAN MANFAAT IDE 
4.1. Tujuan 
Pembuatan ide "Sistem Deteksi Dini Longsor dan Kebakaran Hutan 
Berbasis IoT" ini memiliki beberapa tujuan utama, yaitu:  
1. Menciptakan alat peringatan dini longsor dan kebakaran hutan yang bisa 
dipasang di daerah pelosok (hutan/tebing) tanpa harus bergantung pada 
jaringan listrik, berkat penggunaan panel surya dan baterai.  
2. Membangun Komunikasi Jaringan Alternatif untuk memecahkan masalah 
susah sinyal di area rawan bencana dengan membangun jalur komunikasi 
menggunakan radio LoRa yang diteruskan ke IoT Gateway, sehingga data 
dari pelosok tetap bisa masuk ke internet.  
3. Mendukung Konsep Smart City: Mewujudkan subtema "Climate Disaster 
Technology" dengan membuat inovasi mitigasi iklim yang cerdas untuk 
melindungi infrastruktur kota dan warganya.  
4.2. Manfaat 
Apabila sistem ini direalisasikan, akan ada banyak manfaat nyata yang 
bisa dirasakan, di antaranya:  
1. Menyelamatkan warga dengan peringatan dini Jika terjadi tanah miring 
atau suhu panas, warga di sekitar lokasi akan langsung mendapat 
peringatan keras dari buzzer dan lampu darurat, serta notifikasi di aplikasi. 
Ini memberikan kesempatan bagi warga untuk segera evakuasi sebelum 
bencana besar benar-benar terjadi.  
2. Mempermudah Pemantauan Jarak Jauh bagi Petugas: Tim SAR, BPBD, 
atau pemerintah daerah. Kondisi tanah dan hutan bisa dipantau secara 
real-time lewat layar smartphone.  
3. Meminimalisir Kerugian Materil: Dengan adanya deteksi dini, baik untuk 
potensi longsor maupun awal kebakaran hutan, penanganan bisa dilakukan 
jauh lebih cepat. Warga memiliki jeda waktu untuk menyelamatkan harta 
benda, kendaraan, atau hewan ternak. 
3 
5. BATASAN DAN SASARAN PENGGUNA 
5.1. Batasan 
Dalam perancangan ide "Sistem Deteksi Dini Longsor dan Kebakaran 
Hutan Berbasis IoT" ini, kami menetapkan beberapa batasan agar fokus 
pengembangan alat tetap terarah dan realistis, yaitu:  
1. Fokus pada Parameter Fisik: Proyek ini dibatasi pada deteksi pergerakan 
mekanis tanah (seperti perubahan kemiringan) serta parameter suhu dan 
kelembaban. Alat ini murni berfungsi sebagai sensor fisik untuk 
peringatan dini, dan tidak mencakup analisis geologi mendalam terkait 
struktur lapisan batuan atau komposisi kimiawi tanah.  
2. Ketergantungan pada Jaringan Gateway: Komunikasi jarak jauh alat ini 
sangat bergantung pada modul LoRa dan IoT Gateway. Jika gateway 
mengalami pemadaman total atau kehilangan akses internet (WiFi), maka 
data tidak akan terkirim ke aplikasi mobile. 
3. Fokus Bencana: Alat ini dirancang secara spesifik hanya untuk mendeteksi 
indikasi awal tanah longsor (pergerakan tebing) dan kebakaran hutan (titik 
panas/suhu ekstrem). Alat ini tidak diperuntukkan untuk mendeteksi 
bencana lain seperti banjir atau gempa bumi.  
5.2. Sasaran Pengguna 
Apabila ide alat mitigasi ini direalisasikan, pihak-pihak yang akan menjadi 
pengguna utama dan menerima dampak positifnya secara langsung adalah:  
1. Masyarakat di Daerah Rawan Bencana: Khususnya warga yang tinggal di 
kawasan perbukitan, lereng curam, atau di perbatasan kawasan hutan.  
2. Perangkat Desa (RT/RW/Kepala Desa): Sebagai pemegang akses aplikasi 
mobile, perangkat desa bisa memantau kondisi lingkungan mereka secara 
real-time. Jika ada notifikasi bahaya dari alat, mereka bisa segera 
mengambil keputusan untuk mengarahkan evakuasi warga.  
3. BPBD (Badan Penanggulangan Bencana Daerah) dan Tim SAR: Sebagai 
instansi resmi, BPBD bisa mengintegrasikan data dari IoT Gateway ke 
ruang kontrol mereka, sehingga respon pengiriman bantuan atau tim 
pemadam bisa dilakukan lebih cepat sebelum skala bencana membesar. 
4 
6. ANALISIS 
6.1. Alat dan Bahan yang digunakan 
Dalam merancang sistem deteksi dini ini, kami melakukan analisis 
kebutuhan komponen secara matang. Pemilihan alat dan bahan didasarkan pada 
tiga pertimbangan utama: kemampuan bertahan lama di lapangan (sejalan dengan 
tema "Long Life Legacy"), akurasi pembacaan pada kondisi lingkungan ekstrim 
luar ruangan, serta efisiensi jumlah komponen agar sistem tetap ringkas dan 
sangat hemat daya (low-power). Berikut adalah rincian komponen utama yang 
kami gunakan: 
Komponen Fungsi & Alasan  
Mikrokontroler ESP32 + Modul LoRa  
Fungsi: Sebagai "otak" utama sistem 
yang memproses data sensor, 
menjalankan logika deep sleep, serta 
mengirim data jarak jauh. 
Alasan: ESP32 memiliki fitur deep 
sleep bawaan yang sangat hemat daya. 
Dipadukan dengan modul LoRa, alat 
mampu mengirim sinyal darurat dari 
area terpencil tanpa butuh jaringan 
WiFi atau sinyal seluler.  
Sensor Accelerometer (MPU6050)  
Fungsi: Mengukur kemiringan tanah 
(tilt) sekaligus mendeteksi getaran 
(vibration) pada tebing. 
Alasan: Sensor ini membaca arah 
gravitasi secara langsung sehingga 
akurat memantau pergerakan tanah. 
Menggunakan satu chip untuk dua 
fungsi sekaligus sangat memangkas 
penggunaan komponen. 
Sensor Kelembaban Tanah (Tipe 
Capacitive)  Fungsi: Mendeteksi kenaikan kadar 
air di dalam tanah sebagai pemicu 
utama longsor. 
 
5 
 
Alasan: Kami memilih tipe kapasitif 
karena tidak mengalami korosi (karat) 
pada elektrodanya, sehingga jauh lebih 
awet saat ditanam di tanah basah 
dalam jangka waktu lama. 
 
Sensor Suhu & Kelembapan Udara 
(DHT22)  Fungsi: Memantau kondisi udara 
sekitar sebagai indikator peringatan 
dini kerawanan kebakaran hutan. 
Alasan: Satu sensor mampu membaca 
dua parameter. Kombinasi suhu panas 
dan udara kering merupakan indikator 
kuat awal karhutla, sesuai dengan 
standar pemantauan lingkungan. 
 
Buzzer Aktif + LED Strip Darurat  
Fungsi: Sebagai sistem peringatan 
lokal (suara bising dan visual) di 
lokasi pemasangan. 
Alasan: Memberi peringatan instan ke 
warga di sekitar lokasi tanpa 
bergantung pada koneksi internet. Jika 
jaringan komunikasi putus, alarm 
lokal akan tetap berbunyi. 
 
Panel Surya + Baterai 18650 + Modul 
Charger  Fungsi: Menjadi sistem catu daya 
mandiri (auto-charging). 
Alasan: Mengingat lokasi rawan tidak 
terjangkau listrik, kombinasi ini 
memungkinkan alat beroperasi secara 
independen dalam waktu yang lama. 
 
Kotak Pelindung Waterproof 
Fungsi: Melindungi perangkat 
elektronik dari air hujan, panas terik, 
dan embun. 
 
6 
 
Alasan: Alat ditempatkan di luar 
ruangan (outdoor) 24 jam penuh, 
sehingga casing anti-air adalah syarat 
mutlak mencegah korsleting. 
IoT Gateway (ESP32 + LoRa + WiFi)  
Fungsi: Menjembatani sinyal radio 
dari alat di lokasi rawan agar 
terhubung ke internet. 
Alasan: Gateway ditempatkan di area 
pemukiman terdekat yang memiliki 
akses WiFi, sehingga data telemetri 
dari LoRa bisa diteruskan dan diakses 
secara real-time via aplikasi ponsel. 
6.2. Konsep yang diterapkan 
Dalam pembuatan sistem deteksi dini ini, kami menerapkan beberapa 
konsep teknis utama agar alat bisa beroperasi secara cerdas dan awet di alam liar:  
1. Manajemen Daya Adaptif: Mikrokontroler memakai sistem deep sleep dan 
hanya bangun rutin tiap 6 jam. Namun, kami mengaktifkan fitur 
motion-interrupt pada sensor. Jika ada guncangan atau tanah miring 
mendadak, alat otomatis bangun seketika tanpa menunggu siklus 6 jam.  
2. Pembacaan Gravitasi Absolut: Kami murni memakai accelerometer 
(bukan gyroscope) untuk membaca kemiringan tanah. Gyroscope rawan 
mengalami penumpukan error (drift) seiring waktu, sedangkan 
accelerometer membaca tarikan gravitasi bumi secara langsung sehingga 
akurasinya tetap stabil tanpa perlu kalibrasi ulang terus-menerus.  
3. Validasi Kondisi: Alarm tidak akan asal berbunyi karena senggolan hewan. 
Status bahaya baru aktif jika memenuhi 3 syarat: kemiringan melewati 
batas, pergerakan terbaca stabil (bukan getaran sesaat), dan dibarengi 
perubahan drastis pada kelembapan tanah.  
7 
4. Status Peringatan Bertingkat: Output peringatan tidak cuma 
"Aman/Bahaya", tapi dibagi menjadi tiga level mengikuti standar resmi 
kebencanaan: Waspada, Siaga, dan Awas.  
5. Komunikasi Berlapis: Menjembatani kendala blank spot dengan arsitektur 
berantai: Sensor Node (LoRa) → IoT Gateway terdekat → Jaringan 
Internet (WiFi) → Aplikasi.  
6.3. Analisis Risiko Dan Mitigasi 
Mengingat alat dipasang di lingkungan ekstrem, kami menyiapkan 
beberapa analisis risiko dan mitigasinya:  
1. Kegagalan Jaringan Internet: Jika IoT Gateway di pemukiman mati listrik 
atau WiFi putus, sistem mitigasi lokal (buzzer aktif dan LED strip darurat) 
di titik rawan tetap akan berbunyi karena menggunakan daya baterai 
mandiri.  
2. Kendala Suplai Daya: Jika cuaca mendung berhari-hari atau panel surya 
tertutup dedaunan, baterai 18650 yang kami gunakan dirancang 
berkapasitas besar untuk menopang daya alat (backup) selama berhari-hari 
dalam mode deep sleep.  
8 
7. IMPLEMENTASI DAN CARA KERJA 
Berikut adalah Data Flow Diagram (DFD) dari Sistem Deteksi Dini Longsor dan 
Kebakaran Hutan Berbasis IoT: 
9 
Penjelasan DFD Berdasarkan DFD di atas, aliran data dimulai dari entitas 
Lingkungan Alam yang memberikan input fisik (kemiringan, getaran, suhu, 
kelembapan) ke Node Sensor. Setelah itu data diproses untuk menentukan status 
bahaya. Jika bahaya, data mengalir ke dua arah: (1) Ke hardware Buzzer & LED 
sebagai peringatan lokal, dan (2) Ke IoT Gateway dalam bentuk sinyal radio 
LoRa. Gateway kemudian mengubah sinyal tersebut menjadi paket data internet 
(WiFi) dan mengirimkannya ke Cloud Server. Terakhir, data dari server mengalir 
ke Aplikasi Mobile sebagai bentuk informasi dan notifikasi visual bagi user.  
Cara dan Alur Kerja Sistem Alur kerja sistem ini dirancang efisien dan terbagi ke 
dalam beberapa fase operasional:  
1. Fase Standby: Dalam kondisi normal, mikrokontroler (ESP32) dan seluruh 
sensor berada dalam mode deep sleep. Sistem hanya akan bangun secara 
otomatis setiap 6 jam sekali, membaca data lingkungan sebentar (untuk 
lapor status "Aman"), mengirimnya via LoRa, lalu kembali tidur. 
2. Fase Deteksi Anomali: Apabila tiba-tiba terjadi pergerakan tanah atau 
getaran tebing, fitur motion-interrupt pada sensor accelerometer akan 
memicu tegangan kejut yang langsung membangunkan ESP32 saat itu 
juga, tanpa perlu menunggu siklus 6 jam.  
3. Fase Validasi Data: Setelah terbangun mendadak, ESP32 langsung 
mengecek sensor lain. Jika tanah miring dan kelembaban tanah sangat 
tinggi, sistem menyimpulkan indikasi longsor. Sebaliknya, jika suhu udara 
mendadak ekstrem dan kelembaban sangat kering, sistem menyimpulkan 
indikasi awal kebakaran hutan.  
4. Fase Peringatan Lokal: Sesaat setelah status ditetapkan menjadi 
"Waspada", "Siaga", dan "Awas", alat langsung menyalakan Buzzer dan 
LED Strip darurat di lokasi. Memberi peringatan instan pada warga atau 
pekerja yang ada di sekitar area tersebut.  
5. Fase Pengiriman Jarak Jauh: Data darurat ditembakkan menggunakan 
modul LoRa. Sinyal ini menembus hutan dan tebing hingga ditangkap oleh 
IoT Gateway di pemukiman. Gateway memforward data tersebut melalui 
WiFi ke database, sehingga aplikasi mobile milik perangkat desa dan 
BPBD akan berbunyi membunyikan notifikasi darurat.  
10 
8. DESAIN 
8.1. Arsitektur Perangkat Lunak 
Berdasarkan bagan arsitektur perangkat lunak di atas, sistem komunikasi 
dan pengolahan data kami bagi menjadi tiga lapisan (layer) utama yang bekerja 
secara berurutan. Pendekatan ini memastikan aliran data dari pelosok hutan atau 
tebing bisa sampai ke layar smartphone pengguna secara real-time dan stabil. 
Berikut adalah penjelasan tiap lapisannya:  
1. Layer 1: Firmware & Hardware Pada lapisan ini, mikrokontroler bertugas 
mengumpulkan data dari tiga sensor dengan protokol komunikasi yang 
berbeda: Sensor Kelembapan melalui jalur Analog, Sensor DHT22 melalui 
jalur Digital, dan Sensor MPU6050 melalui jalur I2C. Setelah data 
terkumpul, ESP32 memaketkan data tersebut dan mengirimkannya melalui 
11 
komunikasi radio LoRa menuju perangkat IoT Gateway (ESP32 + WiFi) 
yang ditempatkan di area pemukiman yang memiliki akses internet.  
2. Layer 2: Cloud & Backend Lapisan ini berfungsi sebagai pusat 
penyimpanan dan lalu lintas data. IoT Gateway yang sudah terhubung ke 
jaringan internet akan meneruskan data dari jaringan LoRa menuju 
database. Proses pengiriman ini difasilitasi oleh protokol komunikasi IoT 
yang ringan dan cepat, yaitu MQTT atau HTTP.  
3. Layer 3: Frontend Aplikasi Mobile Lapisan terakhir adalah aplikasi mobile 
yang diakses langsung oleh pengguna. Aplikasi ini melakukan sinkronisasi 
secara real-time dengan database di awan. Berdasarkan data yang ditarik, 
aplikasi mengeksekusi dua tindakan utama: menampilkan informasi secara 
visual secara berkala melalui Dashboard & Grafik, serta memicu 
peringatan instan berupa Push Notification ke smartphone pengguna jika 
algoritma mendeteksi anomali bencana.  
8.2. Arsitektur Perangkat Keras 
12 
Rancangan fisik dan arsitektur perangkat keras pada sistem ini didesain 
secara kokoh, ringkas, dan berfokus pada ketahanan di luar ruangan (outdoor). 
Karena alat ini ditargetkan untuk menyala 24 jam di lingkungan ekstrem seperti 
tebing rawan longsor atau pinggiran hutan, tata letak komponen disusun dengan 
fungsi spesifik sebagai berikut:  
1. Panel Surya: Ditempatkan di posisi paling atas menyerupai kanopi atau 
payung. Posisi ini bertujuan agar panel mendapatkan paparan sinar 
matahari paling maksimal tanpa terhalang bayangan komponen lain, 
sekaligus melindungi kotak di bawahnya dari terik matahari langsung. 
Panel ini adalah sumber energi utama untuk sistem auto-charging baterai.  
2. Kotak Elektronik: Berfungsi sebagai "ruang kendali" yang melindungi 
komponen vital seperti mikrokontroler ESP32, baterai, modul LoRa, serta 
sensor kemiringan/getaran dan sensor suhu udara. Kotak ini tertutup rapat 
untuk mencegah masuknya air hujan, kelembapan embun, atau serangga 
yang bisa memicu korsleting.  
3. LED Strip + Buzzer: Komponen peringatan lokal ini diletakkan menempel 
pada sisi luar kotak elektronik. Tujuannya agar pendaran lampu berwarna 
merah peringatan dan suara bising dari buzzer bisa langsung terlihat serta 
terdengar jelas oleh warga atau petugas yang sedang berada di sekitar 
lokasi kejadian.  
4. Tiang Penyangga Tertanam: Alat ditopang oleh tiang utama yang ditanam 
langsung ke dalam permukaan tanah yang miring (seperti ilustrasi lereng). 
Penanaman ini memastikan alat berdiri sangat stabil dan tidak mudah 
bergoyang karena tiupan angin, sehingga sensor accelerometer di dalam 
kotak tidak menghasilkan data error (alarm palsu). Jika tanah benar-benar 
bergeser atau longsor, tiang ini akan ikut miring dan langsung memicu 
sistem.  
5. Probe Kelembapan Tanah: Sensor ini dipasang secara terpisah dari tiang 
utama dan ditancapkan langsung ke dalam tanah di dekat alat. Posisi 
tertanam ini memungkinkan sensor membaca kadar air dan tingkat 
kelembapan di dalam struktur tanah secara akurat, yang merupakan 
indikator krusial sebelum terjadinya tanah longsor.  
13 
8.3. Representasi User Interface 
Tampilan Dashboard Utama (Kondisi Aman / Active & Stable) Seperti 
yang terlihat pada gambar pertama, saat kondisi lingkungan terpantau normal, 
aplikasi akan menampilkan antarmuka pemantauan standar:  
1. Indikator Status: Terdapat kartu status berwarna hijau bertuliskan "Active 
& Stable" di bagian atas, menandakan bahwa seluruh sensor berfungsi 
baik dan tidak ada anomali.  
2. Panel Analytics : Menampilkan grafik garis pergerakan rata-rata suhu dan 
variansi data selama 7 hari terakhir. Fitur ini sangat berguna bagi petugas 
untuk melihat tren cuaca atau kondisi tanah secara visual.  
3. Live Telemetry: Menampilkan kartu data pembacaan angka sensor secara 
langsung (misalnya Suhu 24.1°C dan Kelembapan 42%), memberikan 
informasi presisi dari lokasi titik pantau.  
14 
8.4. Detail Algoritma 
kami merancang algoritma perangkat lunak. Berikut adalah urutan logika 
program yang ditanamkan pada mikrokontroler di lokasi titik pantau:  
1. Fase Start: Saat pertama kali dinyalakan, ESP32 melakukan pengaturan 
awal pada semua pin sensor, modul LoRa, dan mematikan relay.  
2. Fase Deep Sleep: Setelah setup selesai, mikrokontroler memutus aliran 
listrik ke sensor yang tidak perlu untuk menghemat baterai, lalu masuk ke 
mode deep sleep. Timer internal diset selama 6 jam.  
3. Fase Bangun: Sistem diprogram untuk bisa terbangun melalui dua cara: 
a. Wake-up Timer: Bangun secara rutin setelah 6 jam. 
b. Wake-up Interrupt: Wake up trigger jika pin interrupt pada sensor 
mendeteksi pergerakan tanah yang melewati batas wajar. 
4. Fase Pembacaan Data: Setelah bangun, ESP32 kembali mengalirkan daya 
ke semua sensor dan mengambil sampel data berupa: derajat kemiringan, 
getaran, persentase kelembapan tanah, suhu, dan kelembapan udara.  
5. Fase Validasi dan Pengambilan Keputusan: 
a. Deteksi Longsor: JIKA derajat kemiringan berubah drastis DAN 
kelembapan tanah berada di persentase yang sangat basah, MAKA 
sistem menetapkan status "BAHAYA LONGSOR". 
b. Deteksi Karhutla: JIKA suhu udara terbaca sangat ekstrem DAN 
kelembapan udara sangat kering, MAKA sistem menetapkan status 
"BAHAYA KARHUTLA". 
c. Kondisi Normal: JIKA pembacaan sensor berada di batas wajar, 
MAKA sistem menetapkan status "AMAN". 
6. Fase Eksekusi:  
a. Jika status "BAHAYA", ESP32 langsung mengaktifkan pin relay 
untuk menyalakan Buzzer dan LED Strip, lalu merakit paket data 
darurat dan menembakkannya via LoRa ke Gateway. 
b. Jika status "AMAN", Buzzer dan LED tetap mati, ESP32 hanya 
menembakkan data telemetri rutin via LoRa. 
7. Fase Reset: Setelah pengiriman data sukses, ESP32 mereset variabel dan 
kembali masuk ke Fase Mode Tidur (Langkah 2).  
15 
9. DAFTAR PUSTAKA 
Arduino Project Hub. (n.d.). Capacitive Soil Moisture Sensor Tutorial & 
Calibration. Arduino Project Hub. Dari https://projecthub.arduino.cc/ 
Last Minute Engineers. (n.d.). In-Depth: ESP32 Deep Sleep & Wakeup Sources. 
Last 
Minute 
Engineers 
Tutorials. 
https://lastminuteengineers.com/esp32-deep-sleep-wakeup-sources/ 
dari 
Last Minute Engineers. (n.d.). How MPU6050 Accelerometer and Gyroscope 
Sensor Works & Interface. Last Minute Engineers Tutorials. dari 
https://lastminuteengineers.com/mpu6050-accel-gyro-arduino-tutorial/ 
Tim Riset Tempo. (2021). Longsor di Indonesia dalam Angka. Tempo.co Data. 
dari https://www.tempo.co/data/data/longsor-di-indonesia-dalam-angka-2111234 
16 
10. LAMPIRAN 
Berisi kartu identitas siswa. 
17 