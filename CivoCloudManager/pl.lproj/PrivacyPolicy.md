# Polityka Prywatności

## Civo Cloud Manager

**Data wejścia w życie:** kwiecień 2026
**Ostatnia aktualizacja:** kwiecień 2026

**Administrator danych:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Niemcy
E-mail: moin@berger-rosenstock.de

---

## 1. Wprowadzenie

Niniejsza Polityka Prywatności wyjaśnia, w jaki sposób Marcel R. G. Berger, działający jako Berger & Rosenstock GbR („my", „nas", „nasz"), postępuje z informacjami w związku z aplikacją Civo Cloud Manager („Aplikacja").

Zobowiązujemy się do ochrony Państwa prywatności oraz przestrzegania obowiązujących przepisów o ochronie danych, w tym między innymi:

- Ogólnego rozporządzenia UE o ochronie danych (RODO, rozporządzenie (UE) 2016/679)
- Niemieckiej federalnej ustawy o ochronie danych (BDSG)
- Brytyjskiego ogólnego rozporządzenia o ochronie danych (UK GDPR) oraz Data Protection Act 2018
- Szwajcarskiej federalnej ustawy o ochronie danych (FADP / revDSG)
- California Consumer Privacy Act (CCPA) oraz California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) oraz innych stanowych aktów prawnych w USA
- Kanadyjskiej ustawy Personal Information Protection and Electronic Documents Act (PIPEDA) oraz ustaw prowincjonalnych
- Australijskiej ustawy Privacy Act 1988 oraz Australian Privacy Principles (APPs)
- Brazylijskiej ogólnej ustawy o ochronie danych (LGPD, ustawa nr 13.709/2018)
- Japońskiej ustawy o ochronie danych osobowych (APPI)
- Południowokoreańskiej ustawy Personal Information Protection Act (PIPA)
- Singapurskiej ustawy Personal Data Protection Act (PDPA)
- Tajlandzkiej ustawy Personal Data Protection Act (PDPA 2019)
- Chińskiej ustawy Personal Information Protection Law (PIPL)
- Indyjskiej ustawy Digital Personal Data Protection Act 2023 (DPDP Act)
- Południowoafrykańskiej ustawy Protection of Personal Information Act (POPIA)
- Prawa o ochronie danych osobowych Zjednoczonych Emiratów Arabskich (PDPL)
- Nowozelandzkiej ustawy Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, USA)

---

## 2. Zasada Zerowego Zbierania Danych

**Nie zbieramy, nie przechowujemy, nie przesyłamy ani nie przetwarzamy żadnych danych osobowych na naszych serwerach.**

Aplikacja działa w całości na Państwa urządzeniu. Cała konfiguracja, dane uwierzytelniające oraz preferencje są przechowywane lokalnie. Nie posiadamy serwerów, które odbierałyby Państwa dane. Nie prowadzimy żadnej infrastruktury backend służącej do zbierania danych, analityki, raportowania awarii ani telemetrii.

Ponieważ nie przetwarzamy danych osobowych pod naszą kontrolą, większość obowiązków wynikających z przepisów o ochronie danych (obowiązki administratora, obowiązki dotyczące transferów międzynarodowych, powiadomienia o naruszeniach itp.) nie ma do nas zastosowania jako wydawcy niniejszej Aplikacji. Sekcja 10 mimo to opisuje prawa, które przysługują Państwu na mocy obowiązującego prawa.

---

## 3. Dane przechowywane na Państwa urządzeniu

Aplikacja przechowuje następujące dane lokalnie na Państwa urządzeniu macOS. Żadne z tych danych nie są przesyłane na nasze serwery.

### 3.1 Dane uwierzytelniające

- **Klucz API Civo** — przechowywany w Pęku kluczy (Keychain) macOS (szyfrowanie sprzętowe) — używany do uwierzytelnienia w Civo Cloud API
- **Dane uwierzytelniające Kubeconfig** — przechowywane wyłącznie w pamięci podczas aktywnych sesji, nigdy nie zapisywane na dysku
- **Dane uwierzytelniające Object Store (Access Key ID / Secret)** — pobierane z API Civo na żądanie, przechowywane wyłącznie w pamięci

### 3.2 Preferencje

- **Wybrany region** (UserDefaults) — aktywny kod regionu Civo
- **Zarządzane zapory** (UserDefaults, JSON) — konfiguracje zapór śledzone przez Aplikację
- **Uruchamianie przy logowaniu** (UserDefaults) — preferencja automatycznego startu
- **Stan onboardingu** (UserDefaults) — flaga ukończenia konfiguracji
- **Presety IP** (UserDefaults, JSON) — nazwane przez użytkownika adresy IP dla reguł zapory

### 3.3 Tymczasowe dane runtime

- **Wykryty publiczny adres IP** — przechowywany w pamięci podczas sesji, nigdy nie zapisywany
- **Odpowiedzi API** — przechowywane w pamięci podczas ich wyświetlania, nigdy nie zapisywane poza sesją

### 3.4 Status zakupu

Zarządzany w całości przez Apple StoreKit. Nie otrzymujemy, nie przechowujemy ani nie przetwarzamy żadnych informacji dotyczących płatności.

---

## 4. Podstawa prawna przetwarzania (RODO)

Ponieważ nie działamy jako administrator ani podmiot przetwarzający dane osobowe zbierane poprzez Aplikację, podstawy przetwarzania z art. 6 RODO nie mają do nas zastosowania. W zakresie, w jakim działanie Aplikacji obejmuje lokalne przetwarzanie na Państwa urządzeniu, odbywa się ono w oparciu o:

- **Wykonanie umowy** (art. 6 ust. 1 lit. b RODO) — zapewnienie funkcjonalności, dla której zainstalowali Państwo Aplikację
- **Zgodę** (art. 6 ust. 1 lit. a RODO) — gdy wyraźnie inicjują Państwo działania takie jak wykrywanie IP, tworzenie reguł zapory lub uwierzytelnianie Touch ID

Żadne przetwarzanie nie odbywa się na mocy art. 6 ust. 1 lit. a, c, d, e ani f RODO na infrastrukturze prowadzonej przez nas.

---

## 5. Sposób wykorzystania danych

Dane na Państwa urządzeniu wykorzystywane są wyłącznie w celu:

- Uwierzytelnienia względem Civo Cloud API, serwerów API Kubernetes oraz punktów końcowych magazynu obiektowego zgodnego z S3, do których Państwo kierują Aplikację
- Zarządzania Państwa zasobami Civo Cloud (instancje, klastry, bazy danych, zapory itp.)
- Wykrywania Państwa publicznego adresu IPv4 w celu otwierania i zamykania reguł zapory
- Lokalnego wyświetlania statusu zasobów, szacunków kosztów oraz dzienników aktywności
- Przetwarzania jednorazowego zakupu w aplikacji poprzez Apple StoreKit

Dane nigdy nie są przez nas udostępniane, sprzedawane, wypożyczane ani w inny sposób ujawniane osobom trzecim.

---

## 6. Usługi stron trzecich

Aplikacja komunikuje się bezpośrednio z następującymi usługami stron trzecich na Państwa wyraźne polecenie. Nie jesteśmy stroną tej komunikacji.

### 6.1 Civo Cloud API (api.civo.com)

- **Cel:** Zarządzanie Państwa infrastrukturą Civo Cloud
- **Wysyłane dane:** Państwa klucz API Civo (jako nagłówek uwierzytelniania), żądania zarządzania zasobami
- **Operator:** Civo Ltd, Zjednoczone Królestwo
- **Polityka prywatności:** https://www.civo.com/privacy

### 6.2 Serwery API Kubernetes

- **Cel:** Dostęp do węzłów klastra, podów, logów, wdrożeń i metryk
- **Wysyłane dane:** Dane uwierzytelniające certyfikatem klienta z Państwa kubeconfig (PKCS#12 mTLS)
- **Operator:** Operator klastra Kubernetes (Państwa klaster Civo; Państwo kontrolują punkt końcowy)

### 6.3 Civo Object Storage (zgodne z S3)

- **Cel:** Przeglądanie, przesyłanie i pobieranie plików w Państwa magazynach obiektowych
- **Wysyłane dane:** Żądania zgodne z S3 podpisane Państwa danymi uwierzytelniającymi magazynu obiektowego (AWS Signature V4)
- **Operator:** Civo Ltd

### 6.4 Usługi wykrywania IP

- **Cel:** Wykrywanie Państwa publicznego adresu IPv4 w celu zarządzania regułami zapory
- **Wykorzystywane usługi:** ipify.org, ifconfig.me, icanhazip.com (łańcuch awaryjny)
- **Wysyłane dane:** Standardowe żądanie HTTPS (Państwa adres IP jest z natury widoczny dla tych usług)
- **Otrzymywane dane:** Państwa publiczny adres IPv4

### 6.5 Apple App Store / StoreKit

- **Cel:** Przetwarzanie zakupów w aplikacji, weryfikacja uprawnień, obsługa Chmury rodzinnej (Family Sharing)
- **Wysyłane dane:** Zarządzane w całości przez framework StoreKit firmy Apple
- **Operator:** Apple Inc.
- **Polityka prywatności:** https://www.apple.com/legal/privacy/

### 6.6 Niewykorzystywane SDK

**Nie** integrujemy żadnego z następujących rozwiązań:

- SDK analityczne (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog itp.)
- SDK raportowania awarii (Crashlytics, Sentry, Bugsnag itp.)
- SDK reklamowe (AdMob, Meta Audience Network, AppLovin itp.)
- SDK atrybucji (AppsFlyer, Adjust, Branch, Kochava itp.)
- Frameworki do testów A/B
- SDK mediów społecznościowych
- Dostawcy uwierzytelniania strony trzeciej

---

## 7. Międzynarodowe transfery danych

Nie przekazujemy danych osobowych międzynarodowo, ponieważ nie zbieramy ani nie przetwarzamy danych osobowych.

Przepływy danych inicjowane przez Państwa (wywołania API do Civo, Kubernetes, S3, wykrywanie IP) mogą obejmować transmisję transgraniczną. Takie transfery podlegają politykom prywatności i mechanizmom transferu danych poszczególnych operatorów. W przypadku użytkowników z EOG/Zjednoczonego Królestwa Civo Ltd opiera się na decyzjach o odpowiednim stopniu ochrony Zjednoczonego Królestwa i UE oraz, w stosownych przypadkach, na standardowych klauzulach umownych (SCC).

---

## 8. Retencja danych

Nie przechowujemy żadnych danych. Wszystkie dane Aplikacji są przechowywane lokalnie na Państwa urządzeniu i znajdują się pod Państwa wyłączną kontrolą.

- **Odinstalowanie Aplikacji** usuwa preferencje zapisane w UserDefaults (zwykle `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Elementy w Pęku kluczy** mogą pozostać po odinstalowaniu; można je usunąć ręcznie poprzez aplikację Dostęp do pęku kluczy
- **Bufory kosztów z zeszłego miesiąca** są przechowywane lokalnie i usuwane wraz z kontenerem po odinstalowaniu

---

## 9. Bezpieczeństwo danych

Chociaż nie zbieramy Państwa danych, wdrażamy następujące środki bezpieczeństwa w Aplikacji:

- **Przechowywanie klucza API:** Pęk kluczy macOS z szyfrowaniem sprzętowym (Secure Enclave, gdzie dostępny)
- **Sekrety magazynu obiektowego:** Chronione przez Touch ID / hasło systemowe za pomocą frameworku LocalAuthentication
- **Dane uwierzytelniające Kubeconfig:** Przechowywane wyłącznie w pamięci podczas aktywnych sesji, nigdy nie zapisywane na dysku
- **Komunikacja sieciowa:** HTTPS/TLS 1.2+ dla całej komunikacji API
- **Uwierzytelnianie certyfikatem:** API Kubernetes używa mTLS z certyfikatem klienta PKCS#12
- **App Sandbox:** Aplikacja działa w ramach App Sandbox macOS z minimalnymi wymaganymi uprawnieniami
- **Hardened Runtime:** Dodatkowe wzmocnienia bezpieczeństwa w środowisku uruchomieniowym
- **Brak telemetrii:** Żadne dane użytkowania, analityczne ani raporty awarii nie są nigdzie przesyłane
- **Brak trwałego logowania:** Logi używają `os.Logger` z `privacy: .private` i nie są eksportowane

Żaden system nie jest w pełni bezpieczny. Zalecamy używanie dedykowanego klucza API z minimalnymi uprawnieniami Civo wymaganymi dla Państwa pracy.

---

## 10. Państwa prawa

### 10.1 Prawa na mocy RODO (UE / EOG / Zjednoczone Królestwo)

Przysługuje Państwu prawo do:

- **Dostępu** do swoich danych osobowych (art. 15 RODO) — nie dotyczy, nie przechowujemy żadnych Państwa danych
- **Sprostowania** nieprawidłowych danych (art. 16 RODO) — nie dotyczy
- **Usunięcia** / prawa do bycia zapomnianym (art. 17 RODO) — nie dotyczy; mogą Państwo usunąć dane lokalne poprzez odinstalowanie
- **Ograniczenia** przetwarzania (art. 18 RODO) — nie dotyczy
- **Przenoszenia danych** (art. 20 RODO) — nie dotyczy
- **Sprzeciwu** wobec przetwarzania (art. 21 RODO) — nie dotyczy
- **Wycofania zgody** w dowolnym momencie (art. 7 ust. 3 RODO) — mogą Państwo przestać korzystać z Aplikacji w każdej chwili
- **Złożenia skargi** do organu nadzorczego

Prawa te są spełnione przez naszą politykę zerowego zbierania danych. Gdyby zmieniło się to w przyszłej wersji, poinformujemy Państwa i wdrożymy pełne ramy praw.

### 10.2 Prawa na mocy CCPA / CPRA (Kalifornia, USA)

Mieszkańcy Kalifornii mają prawo do:

- Uzyskania informacji o tym, jakie dane osobowe są zbierane, wykorzystywane, udostępniane lub sprzedawane
- Usunięcia danych osobowych
- Rezygnacji ze sprzedaży lub udostępniania danych osobowych
- Niedyskryminacji za korzystanie z praw prywatności
- Sprostowania nieprawidłowych danych osobowych
- Ograniczenia wykorzystania wrażliwych danych osobowych

Nie sprzedajemy danych osobowych. Nie udostępniamy danych osobowych w celu behawioralnej reklamy międzykontekstowej. Nie zbieramy danych osobowych w rozumieniu CCPA/CPRA.

### 10.3 Prawa na mocy innych stanowych ustaw w USA (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR itp.)

Mieszkańcy stanów Wirginia, Kolorado, Connecticut, Utah, Teksas, Oregon, Iowa, Montana, Floryda, Tennessee, Indiana, Delaware, New Jersey oraz innych stanów USA z ustawodawstwem dotyczącym prywatności mają prawo do dostępu, usunięcia, sprostowania oraz rezygnacji z ukierunkowanej reklamy / sprzedaży / profilowania. Prawa te są spełnione przez naszą politykę zerowego zbierania danych.

### 10.4 Prawa na mocy PIPEDA i ustaw prowincjonalnych (Kanada)

Mieszkańcy Kanady mają prawo do dostępu, kwestionowania prawidłowości, wycofania zgody oraz składania skarg do Biura Komisarza ds. Prywatności Kanady (lub organów prowincjonalnych w Quebecu, Kolumbii Brytyjskiej, Albercie).

### 10.5 Prawa na mocy Australian Privacy Act

Mieszkańcy Australii mają prawo do dostępu i sprostowania swoich danych osobowych oraz do składania skarg do Biura Australijskiego Komisarza ds. Informacji (OAIC).

### 10.6 Prawa na mocy LGPD (Brazylia)

Mieszkańcy Brazylii mają prawo do potwierdzenia przetwarzania, dostępu, sprostowania, anonimizacji, przenoszenia, informacji o udostępnianiu oraz wycofania zgody. Skargi można kierować do Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Prawa na mocy APPI (Japonia)

Mieszkańcy Japonii mają prawo do ujawnienia, sprostowania, usunięcia oraz zaprzestania wykorzystywania. Skargi można kierować do Komisji Ochrony Danych Osobowych (PPC).

### 10.8 Prawa na mocy PIPA (Korea Południowa)

Mieszkańcy Korei Południowej mają prawo do dostępu, sprostowania, usunięcia, zawieszenia przetwarzania oraz dochodzenia odszkodowania. Skargi można kierować do Komisji Ochrony Danych Osobowych (PIPC).

### 10.9 Prawa na mocy PDPA (Singapur / Tajlandia)

Mieszkańcy mają prawo do dostępu, sprostowania i wycofania zgody. Skargi można kierować do Personal Data Protection Commission (PDPC) danego kraju.

### 10.10 Prawa na mocy PIPL (Chiny)

Mieszkańcy Chin mają prawo do informacji, decydowania, ograniczenia, odmowy, dostępu, kopiowania, przenoszenia, sprostowania, usunięcia oraz żądania wyjaśnień dotyczących zasad przetwarzania.

### 10.11 Prawa na mocy DPDP Act (Indie)

Mieszkańcy Indii mają prawo do informacji, sprostowania, usunięcia, rozpatrzenia skarg oraz nominacji.

### 10.12 Prawa na mocy POPIA (RPA)

Mieszkańcy Republiki Południowej Afryki mają prawo do dostępu, sprostowania, usunięcia oraz składania skarg do Regulatora Informacji.

### 10.13 Prawa na mocy szwajcarskiej FADP

Mieszkańcy Szwajcarii mają prawo do informacji, dostępu, sprostowania, usunięcia, sprzeciwu oraz przenoszenia danych. Skargi można kierować do Federalnego Komisarza ds. Ochrony Danych i Informacji (EDÖB).

### 10.14 Prawa na mocy NZ Privacy Act

Mieszkańcy Nowej Zelandii mają prawo do dostępu i sprostowania danych osobowych oraz składania skarg do Komisarza ds. Prywatności.

### 10.15 Jak korzystać ze swoich praw

Ponieważ nie przechowujemy żadnych Państwa danych, prawa te są domyślnie spełnione. Jeśli uważają Państwo, że pomimo niniejszej Polityki przechowujemy dane osobowe dotyczące Państwa, prosimy o kontakt: moin@berger-rosenstock.de.

---

## 11. Prywatność dzieci

Aplikacja posiada ocenę wiekową Apple App Store **4+** i dlatego technicznie jest dostępna dla użytkowników w każdym wieku. Jednak Aplikacja jest narzędziem do zarządzania infrastrukturą techniczną przeznaczonym dla administratorów kont Civo Cloud. Posiadanie konta Civo Cloud wymaga, aby posiadacz konta osiągnął wiek umożliwiający zawieranie umów zgodnie z jego jurysdykcją.

**Nie zbieramy świadomie danych osobowych od nikogo, w tym od dzieci poniżej 13. roku życia (COPPA, USA), 16. roku życia (RODO-K, UE) lub odpowiedniego wieku wyrażenia zgody w Państwa jurysdykcji.**

Ponieważ Aplikacja wdraża ścisłą politykę zerowego zbierania danych (patrz sekcja 2), żadne dane osobowe żadnego użytkownika — niezależnie od wieku — nie są zbierane, przesyłane, przechowywane na naszych serwerach ani udostępniane osobom trzecim. Spełnia to wymogi:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, USA)
- **Art. 8 RODO** (UE)
- **PIPEDA** oraz obowiązujących ustaw prowincjonalnych (Kanada)
- **Art. 14 LGPD** (Brazylia)
- **APPI** (Japonia)
- **Australian Privacy Act** oraz AAP 8 dotyczącego prywatności dzieci

Jeśli są Państwo rodzicem lub opiekunem i uważają, że Państwa dziecko podało dane osobowe, prosimy o kontakt: moin@berger-rosenstock.de. Niezwłocznie zbadamy sprawę i usuniemy takie informacje, jeśli zostaną znalezione.

---

## 12. Pliki cookie i śledzenie

Aplikacja jest natywną aplikacją macOS i nie używa plików cookie, web beaconów, znaczników pikselowych, fingerprintingu ani podobnych technologii śledzących.

Aplikacja nie zawiera żadnych osadzonych widoków webowych, które ładowałyby treści stron trzecich.

---

## 13. Zautomatyzowane podejmowanie decyzji

Nie podejmujemy zautomatyzowanych decyzji ani profilowania, które wywołują skutki prawne lub w podobny sposób istotnie na Państwa wpływają. Aplikacja nie wykonuje zautomatyzowanych decyzji opartych na danych osobowych.

---

## 14. Linki i usługi stron trzecich

Aplikacja może zawierać linki do stron internetowych stron trzecich (np. strona Civo, Apple App Store, platforma internetowego rozstrzygania sporów). Nie ponosimy odpowiedzialności za praktyki prywatności ani treści usług stron trzecich. Prosimy o zapoznanie się z ich politykami prywatności przed podaniem danych.

---

## 15. Zmiany niniejszej Polityki

Możemy od czasu do czasu aktualizować niniejszą Politykę Prywatności.

- Istotne zmiany będą komunikowane poprzez Aplikację lub wpis w App Store co najmniej 30 dni przed ich wejściem w życie
- „Data wejścia w życie" na górze odzwierciedla najnowszą wersję
- Nie będziemy z mocą wsteczną zmieniać naszych praktyk prywatności w celu zbierania danych bez uzyskania Państwa wyraźnej zgody

---

## 16. Kontakt

W sprawach związanych z prywatnością lub w celu skorzystania ze swoich praw:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Niemcy
E-mail: moin@berger-rosenstock.de

Mieszkańcy UE mogą również skontaktować się z właściwym organem nadzorczym w swoim państwie członkowskim. Lista organów nadzorczych UE jest dostępna pod adresem: https://edpb.europa.eu/about-edpb/board/members_en

Dla mieszkańców Zjednoczonego Królestwa organem nadzorczym jest Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Postanowienia regionalne

### 17.1 Unia Europejska / Europejski Obszar Gospodarczy

- Działanie jest zgodne z RODO, o ile ma zastosowanie do lokalnego przetwarzania na Państwa urządzeniu
- Organem nadzorczym administratora danych jest właściwy niemiecki krajowy organ ochrony danych
- Ocena skutków dla ochrony danych (DPIA) nie jest wymagana (brak zbierania)

### 17.2 Niemcy

- Zgodność z RODO i Bundesdatenschutzgesetz (BDSG)
- Właściwy organ nadzorczy: Landesbeauftragte für Datenschutz właściwego kraju związkowego (administrator ma siedzibę w Niemczech)

### 17.3 Austria

- Zgodność z RODO i Datenschutzgesetz (DSG)
- Organ nadzorczy: Datenschutzbehörde (DSB)

### 17.4 Szwajcaria

- Zgodność ze zmienioną federalną ustawą o ochronie danych (revDSG), obowiązującą od 1 września 2023 r.
- Organ nadzorczy: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Zjednoczone Królestwo

- Zgodność z UK GDPR i Data Protection Act 2018
- Organ nadzorczy: Information Commissioner's Office (ICO)

### 17.6 Francja

- Zgodność z RODO i Loi Informatique et Libertés
- Organ nadzorczy: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Włochy

- Zgodność z RODO i Codice in materia di protezione dei dati personali
- Organ nadzorczy: Garante per la Protezione dei Dati Personali

### 17.8 Hiszpania

- Zgodność z RODO i Ley Orgánica 3/2018 (LOPDGDD)
- Organ nadzorczy: Agencia Española de Protección de Datos (AEPD)

### 17.9 Holandia

- Zgodność z RODO i Uitvoeringswet AVG (UAVG)
- Organ nadzorczy: Autoriteit Persoonsgegevens (AP)

### 17.10 Polska

- Zgodność z RODO i Ustawą o ochronie danych osobowych
- Organ nadzorczy: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugalia

- Zgodność z RODO i Lei n.º 58/2019
- Organ nadzorczy: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Belgia

- Zgodność z RODO i Loi du 30 juillet 2018
- Organ nadzorczy: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Irlandia

- Zgodność z RODO i Data Protection Act 2018
- Organ nadzorczy: Data Protection Commission (DPC)

### 17.14 Kraje nordyckie (Dania, Finlandia, Norwegia, Szwecja, Islandia)

- Zgodność z RODO (oraz odpowiednikami EOG w Norwegii i Islandii)
- Krajowe organy nadzorcze: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Pozostałe państwa członkowskie UE/EOG

Zgodność z RODO i odpowiednim wdrożeniem krajowym. Wykaz organów nadzorczych: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Stany Zjednoczone

- Zgodność z obowiązującymi stanowymi ustawami o prywatności: CCPA/CPRA (Kalifornia), VCDPA (Wirginia), CPA (Kolorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Teksas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Floryda), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- Sygnały „Do Not Track" oraz „Global Privacy Control" są respektowane tam, gdzie jest to technicznie wykonalne (Aplikacja nie śledzi)
- Zgodność z COPPA dla użytkowników poniżej 13. roku życia

### 17.17 Kanada

- Zgodność z PIPEDA i obowiązującymi ustawami prowincjonalnymi: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Skargi: Biuro Komisarza ds. Prywatności Kanady (OPC) oraz organy prowincjonalne

### 17.18 Meksyk

- Zgodność z Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Organ nadzorczy: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brazylia

- Zgodność z LGPD
- Organ nadzorczy: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentyna, Chile, Kolumbia, Peru, Urugwaj

- Zgodność z krajowymi ustawami o ochronie danych (ustawa 25.326 / ustawa 19.628 / ustawa 1581 / ustawa 29733 / ustawa 18.331)

### 17.21 Australia

- Zgodność z Privacy Act 1988 oraz Australian Privacy Principles (APPs)
- Organ nadzorczy: Office of the Australian Information Commissioner (OAIC)

### 17.22 Nowa Zelandia

- Zgodność z Privacy Act 2020
- Organ nadzorczy: Office of the Privacy Commissioner

### 17.23 Japonia

- Zgodność z Act on the Protection of Personal Information (APPI)
- Organ nadzorczy: Personal Information Protection Commission (PPC)

### 17.24 Korea Południowa

- Zgodność z Personal Information Protection Act (PIPA)
- Organ nadzorczy: Personal Information Protection Commission (PIPC)

### 17.25 Singapur

- Zgodność z Personal Data Protection Act (PDPA)
- Organ nadzorczy: Personal Data Protection Commission (PDPC)

### 17.26 Tajlandia

- Zgodność z Personal Data Protection Act B.E. 2562 (2019)
- Organ nadzorczy: Personal Data Protection Committee

### 17.27 Chiny

- Zgodność z Personal Information Protection Law (PIPL), Cybersecurity Law (CSL) oraz Data Security Law (DSL)

### 17.28 Hongkong

- Zgodność z Personal Data (Privacy) Ordinance (PDPO)
- Organ nadzorczy: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 Indie

- Zgodność z Digital Personal Data Protection Act 2023 (DPDP Act) oraz Information Technology Act 2000
- Organ nadzorczy: Data Protection Board of India

### 17.30 Zjednoczone Emiraty Arabskie

- Zgodność z Federal Decree-Law No. 45 of 2021 (Personal Data Protection Law)

### 17.31 Arabia Saudyjska

- Zgodność z Personal Data Protection Law (PDPL)

### 17.32 Turcja

- Zgodność z Personal Data Protection Law No. 6698 (KVKK)
- Organ nadzorczy: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Izrael

- Zgodność z Privacy Protection Law, 5741-1981 oraz Privacy Protection Regulations
- Organ nadzorczy: Privacy Protection Authority (PPA)

### 17.34 Republika Południowej Afryki

- Zgodność z Protection of Personal Information Act (POPIA)
- Organ nadzorczy: Information Regulator

### 17.35 Kenia, Nigeria, Egipt, Maroko

- Zgodność z krajowymi ustawami o ochronie danych (Data Protection Act 2019 Kenia, NDPR / NDPA Nigeria, ustawa nr 151 z 2020 r. Egipt, ustawa 09-08 Maroko)

### 17.36 Pozostałe jurysdykcje

Dla użytkowników w jurysdykcjach nie wymienionych wyżej podejście zerowego zbierania danych Aplikacji zapewnia zgodność z zasadami minimalizacji danych i ograniczenia celu wspólnymi dla nowoczesnych ram prywatności. Jeśli lokalne prawo przewiduje dodatkowe prawa, są one respektowane.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Wszelkie prawa zastrzeżone.
