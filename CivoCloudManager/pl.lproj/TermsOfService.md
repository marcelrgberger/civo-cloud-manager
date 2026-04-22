# Warunki Użytkowania

## Civo Cloud Manager

**Data wejścia w życie:** kwiecień 2026
**Ostatnia aktualizacja:** kwiecień 2026

**Dostawca:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Niemcy
E-mail: moin@berger-rosenstock.de
Numer VAT: DE455096022

---

## 1. Zakres i akceptacja

### 1.1 Umowa

Niniejsze Warunki Użytkowania („Warunki") regulują dostęp do aplikacji Civo Cloud Manager („Aplikacja") i korzystanie z niej, dostarczanej przez Berger & Rosenstock GbR („Dostawca", „my", „nas", „nasz").

### 1.2 Akceptacja

Instalując Aplikację, uzyskując do niej dostęp lub korzystając z niej, zgadzają się Państwo na związanie niniejszymi Warunkami. Jeśli nie wyrażają Państwo zgody, nie wolno instalować ani korzystać z Aplikacji.

### 1.3 Uprawnienia

Aplikacja posiada ocenę wiekową Apple App Store **4+**. Aby zawrzeć wiążącą umowę, muszą Państwo osiągnąć wiek pozwalający na zawieranie umów w Państwa jurysdykcji. Konto Civo Cloud, wymagane do znaczącego korzystania z Aplikacji, wymaga, aby posiadacz konta osiągnął wiek pozwalający na zawieranie umów.

### 1.4 Użytek biznesowy

Jeżeli korzystają Państwo z Aplikacji w imieniu organizacji, oświadczają Państwo, że posiadają uprawnienia do związania tej organizacji niniejszymi Warunkami.

### 1.5 Umowa licencyjna końcowego użytkownika aplikacji licencjonowanej Apple

Niniejsze Warunki stanowią uzupełnienie umowy licencyjnej końcowego użytkownika aplikacji licencjonowanej Apple (Apple EULA) pomiędzy Państwem a Apple Inc. W przypadku jakiejkolwiek sprzeczności między niniejszymi Warunkami a Apple EULA, pierwszeństwo w objętych przez nią sprawach ma Apple EULA.

---

## 2. Usługi

### 2.1 Opis

Aplikacja jest natywną aplikacją macOS umożliwiającą zarządzanie infrastrukturą Civo Cloud (instancje wirtualne, klastry Kubernetes, bazy danych, zapory, sieci, load balancery, woluminy, magazyny obiektowe, DNS, klucze SSH) oraz bezpośredni dostęp do API Kubernetes przy użyciu własnych danych uwierzytelniających API użytkownika.

Aplikacja łączy się bezpośrednio z Państwa urządzenia z:

- Civo Cloud REST API (`api.civo.com`)
- Serwerami API Kubernetes Państwa klastrów Civo (poprzez mTLS)
- Punktami końcowymi magazynu obiektowego zgodnego z S3 Państwa konta Civo
- Usługami wykrywania publicznego adresu IP (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit do przetwarzania zakupów

Dostawca nie prowadzi żadnej usługi backend, serwera pośredniczącego ani serwera proxy. Cała komunikacja odbywa się bezpośrednio między Państwa urządzeniem a odpowiednimi operatorami stron trzecich.

### 2.2 Funkcje bezpłatne i płatne

Funkcjonalność zarządzania zaporą z paska menu jest bezpłatna. „Pełny dostęp" — który odblokowuje panel zarządzania dla wszystkich wspieranych typów zasobów — jest jednorazowym zakupem w aplikacji przetwarzanym wyłącznie przez Apple App Store (patrz sekcja 7).

### 2.3 Modyfikacje

Dostawca może w dowolnym momencie modyfikować, zawieszać lub wstrzymywać dowolną funkcjonalność Aplikacji. Istotne zmiany dotyczące zakupionych funkcji będą komunikowane co najmniej trzydzieści (30) dni wcześniej, jeżeli jest to wykonalne.

### 2.4 Dostępność

Aplikacja jest udostępniana na zasadzie „w miarę dostępności". Dostawca nie gwarantuje nieprzerwanego dostępu ani dostępności, a funkcjonalność Aplikacji zależy od dostępności usług stron trzecich (Civo Cloud, Apple App Store, dostawcy wykrywania IP), które pozostają poza kontrolą Dostawcy.

---

## 3. Konta

Aplikacja nie wymaga konta u Dostawcy. Całe uwierzytelnianie odbywa się poprzez:

- Państwa klucz API Civo (przechowywany lokalnie w Pęku kluczy macOS)
- Państwa kubeconfig Kubernetes (pobierany z API Civo)
- Państwa Apple ID (do weryfikacji zakupów w aplikacji, obsługiwane przez Apple)

Są Państwo odpowiedzialni za:

- Zachowanie poufności klucza API Civo i innych danych uwierzytelniających
- Wszystkie działania wykonywane przy użyciu Państwa danych uwierzytelniających
- Wszystkie zmiany zasobów, koszty i konsekwencje rozliczeniowe wynikające z korzystania z Aplikacji
- Konfigurację uprawnień klucza API Civo zgodnie z zasadą najmniejszych uprawnień

Dostawca nie ma możliwości dostępu, odzyskania ani resetowania Państwa danych uwierzytelniających Civo. Utrata danych uwierzytelniających pozostaje wyłącznie Państwa odpowiedzialnością.

---

## 4. Treści użytkownika

Aplikacja nie hostuje, nie przechowuje ani nie przesyła treści generowanych przez użytkownika na żaden serwer prowadzony przez Dostawcę. Wszelkie treści, dane lub konfiguracje tworzone przy użyciu Aplikacji (np. nazwy instancji, klucze SSH, etykiety reguł zapory, pliki magazynu obiektowego) są przechowywane:

- Lokalnie na Państwa urządzeniu, lub
- Na Państwa własnym koncie Civo Cloud

Zachowują Państwo wszelkie prawa, tytuły i interesy do takich treści. Dostawca nie rości sobie żadnej licencji, własności ani innego prawa do Państwa treści.

---

## 5. Dopuszczalne użycie

Nie wolno korzystać z Aplikacji w celu:

- Naruszania jakiegokolwiek obowiązującego prawa, regulacji lub praw stron trzecich
- Dostępu do zasobów Civo lub ich obsługi, do których nie są Państwo uprawnieni
- Zakłócania działania usługi Civo Cloud, klastrów Kubernetes, których Państwo nie posiadają, lub samej Aplikacji
- Podejmowania prób inżynierii wstecznej, dekompilacji, demontażu lub wyprowadzania kodu źródłowego z Aplikacji, z wyjątkiem zakresu, w którym takie ograniczenie jest zabronione przez obowiązujące prawo
- Obchodzenia mechanizmów bezpieczeństwa lub kontroli dostępu (w tym paywalla zakupu w aplikacji)
- Dystrybucji, sublicencjonowania, dzierżawy, wynajmu, sprzedaży lub innego komercyjnego wykorzystywania Aplikacji
- Usuwania, zmieniania lub ukrywania zawiadomień o prawach własności, znaków praw autorskich lub znaków towarowych
- Korzystania z Aplikacji do atakowania, kompromitowania lub testowania bezpieczeństwa systemów, których Państwo nie posiadają lub do których testowania nie posiadają Państwo wyraźnej pisemnej zgody
- Korzystania z Aplikacji w dowolnym celu zabronionym przez prawo Republiki Federalnej Niemiec, Unii Europejskiej lub Państwa jurysdykcji zamieszkania

---

## 6. Własność intelektualna

### 6.1 Własność

Aplikacja (w tym kod źródłowy, projekt, tekst, grafika, ikony, lokalizacje oraz wszystkie powiązane prawa własności intelektualnej) jest wyłączną własnością Dostawcy i jest chroniona niemieckim, unijnym i międzynarodowym prawem autorskim, prawem znaków towarowych oraz innymi przepisami dotyczącymi własności intelektualnej.

### 6.2 Udzielenie licencji

Z zastrzeżeniem przestrzegania niniejszych Warunków i Apple EULA, Dostawca udziela Państwu ograniczonej, niewyłącznej, nieprzenoszalnej, niesublicencjonowalnej, odwołalnej licencji na instalację i korzystanie z Aplikacji na urządzeniach Apple, które Państwo posiadają lub kontrolują, wyłącznie do Państwa osobistego lub wewnętrznego biznesowego użytku do zarządzania Państwa infrastrukturą Civo Cloud.

### 6.3 Znaki towarowe stron trzecich

„Civo" jest znakiem towarowym Civo Ltd. „Apple", „App Store", „macOS", „iCloud", „StoreKit", „TestFlight" są znakami towarowymi Apple Inc. „Kubernetes" jest znakiem towarowym The Linux Foundation. Wszystkie inne znaki towarowe stanowią własność ich odpowiednich właścicieli. Dostawca nie jest powiązany, popierany ani sponsorowany przez żadną z tych stron.

### 6.4 Opinie zwrotne

Wszelkie opinie, sugestie lub pomysły, które przekazują Państwo Dostawcy w sprawie Aplikacji, mogą być wykorzystane przez Dostawcę bez ograniczeń i bez wynagrodzenia na Państwa rzecz.

---

## 7. Płatności i subskrypcje

### 7.1 Zakup w aplikacji

„Pełny dostęp" jest sprzedawany jako niekonsumowalny zakup w aplikacji poprzez Apple App Store za jednorazową opłatą. Cena jest wyświetlana w Aplikacji w Państwa walucie lokalnej przed dokonaniem zakupu.

### 7.2 Przetwarzanie płatności

Płatność jest przetwarzana wyłącznie przez Apple Inc. Dostawca nie otrzymuje, nie przechowuje ani nie przetwarza żadnych informacji o płatnościach. Wszelkie sprawy dotyczące płatności, zwrotów i fakturowania są regulowane przez Apple Media Services Terms i Apple EULA.

### 7.3 Chmura rodzinna

„Pełny dostęp" jest włączony dla Apple Family Sharing. Członkowie Państwa grupy Apple Family Sharing będą mogli korzystać z zakupu na własnych urządzeniach, z zastrzeżeniem zasad Apple Family Sharing.

### 7.4 Kody ofertowe Apple

Dostawca może wydawać kody ofertowe Apple w celach promocyjnych. Kody ofertowe można zrealizować poprzez funkcję „Zrealizuj kod" w Aplikacji lub w App Store.

### 7.5 Zwroty

Zwroty są obsługiwane wyłącznie przez Apple zgodnie z polityką zwrotów Apple. Ustawowe prawa konsumenta wynikające z obowiązującego prawa (patrz sekcja 15) pozostają nienaruszone. W szczególności konsumenci z UE są informowani, że ustawowe 14-dniowe prawo odstąpienia od umowy dla treści cyfrowych wygasa, gdy świadczenie rozpoczęło się za Państwa uprzednią wyraźną zgodą — Apple wdraża to poprzez okno potwierdzenia w momencie zakupu.

### 7.6 Podatki

Wyświetlana cena zawiera wszystkie obowiązujące podatki (VAT, podatek obrotowy) określone przez Apple na podstawie Państwa kraju.

---

## 8. Usługi stron trzecich

Korzystanie z Aplikacji wymaga interakcji z usługami stron trzecich. Korzystanie z tych usług podlega ich odpowiednim warunkom:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / Apple ID:** https://www.apple.com/legal/internet-services/terms/
- **Klastry Kubernetes:** warunki operatora Państwa klastra (Civo)

Dostawca nie jest stroną żadnej umowy pomiędzy Państwem a dostawcą usług strony trzeciej i nie odpowiada za dostępność, dokładność ani zachowanie tych usług.

---

## 9. Wyłączenie gwarancji

APLIKACJA JEST DOSTARCZANA W STANIE „TAK JAK JEST" I „W MIARĘ DOSTĘPNOŚCI" BEZ GWARANCJI JAKIEGOKOLWIEK RODZAJU, WYRAŹNYCH LUB DOROZUMIANYCH, W TYM M.IN. GWARANCJI PRZYDATNOŚCI HANDLOWEJ, PRZYDATNOŚCI DO OKREŚLONEGO CELU, DOKŁADNOŚCI, KOMPLETNOŚCI LUB NIENARUSZANIA PRAW.

DOSTAWCA NIE GWARANTUJE, ŻE:

- APLIKACJA BĘDZIE DZIAŁAĆ NIEPRZERWANIE, BEZBŁĘDNIE LUB BEZPIECZNIE
- APLIKACJA BĘDZIE POPRAWNIE WYŚWIETLAĆ, TWORZYĆ, MODYFIKOWAĆ, USUWAĆ ANI ZARZĄDZAĆ ZASOBAMI CIVO CLOUD
- JAKIEKOLWIEK DANE WYŚWIETLANE PRZEZ APLIKACJĘ SĄ DOKŁADNE, KOMPLETNE LUB AKTUALNE
- APLIKACJA JEST ZGODNA ZE WSZYSTKIMI WERSJAMI API CIVO, FUNKCJAMI LUB REGIONAMI

**Operacje destrukcyjne.** Aplikacja może wykonywać nieodwracalne operacje na Państwa koncie Civo Cloud, w tym usuwanie klastrów Kubernetes, baz danych, woluminów, magazynów obiektowych, instancji, kluczy SSH i reguł zapory. Wszystkie operacje destrukcyjne wymagają wyraźnego potwierdzenia użytkownika (zwykle przez wpisanie nazwy zasobu). DOSTAWCA NIE PONOSI ODPOWIEDZIALNOŚCI za niezamierzone usunięcia, utratę danych, przekroczenia kosztów lub uszkodzenia infrastruktury spowodowane korzystaniem z Aplikacji.

Zdecydowanie zalecamy utrzymywanie niezależnych kopii zapasowych wszystkich krytycznych danych, używanie dedykowanego klucza API z minimalnymi uprawnieniami Civo wymaganymi dla Państwa pracy oraz dokładne sprawdzanie wszystkich okien potwierdzających.

Żadne z postanowień niniejszej sekcji nie wyłącza ani nie ogranicza gwarancji, których nie można wyłączyć lub ograniczyć na mocy obowiązującego prawa (patrz sekcja 15).

---

## 10. Ograniczenie odpowiedzialności

W MAKSYMALNYM ZAKRESIE DOZWOLONYM PRZEZ OBOWIĄZUJĄCE PRAWO:

### 10.1 Wyłączenia

DOSTAWCA NIE PONOSI ODPOWIEDZIALNOŚCI ZA ŻADNE POŚREDNIE, PRZYPADKOWE, SPECJALNE, WYNIKOWE, KARNE LUB PRZYKŁADOWE SZKODY, W TYM M.IN.:

- Utratę danych, przychodów, zysków lub szans biznesowych
- Koszty pozyskania usług zastępczych
- Szkody lub usunięcie infrastruktury chmurowej, zasobów lub danych
- Nieautoryzowany dostęp wynikający z skompromitowanych kluczy API

### 10.2 Limit

CAŁKOWITA ŁĄCZNA ODPOWIEDZIALNOŚĆ DOSTAWCY WOBEC PAŃSTWA ZA WSZYSTKIE ROSZCZENIA WYNIKAJĄCE Z LUB ZWIĄZANE Z APLIKACJĄ NIE PRZEKROCZY KWOTY FAKTYCZNIE ZAPŁACONEJ PRZEZ PAŃSTWA ZA APLIKACJĘ W CIĄGU DWUNASTU (12) MIESIĘCY POPRZEDZAJĄCYCH ZDARZENIE STANOWIĄCE PODSTAWĘ ROSZCZENIA.

### 10.3 Wyłączenia z ograniczeń

Żadne z postanowień niniejszych Warunków nie wyłącza ani nie ogranicza odpowiedzialności za:

- Śmierć lub obrażenia ciała spowodowane zaniedbaniem
- Oszustwo lub oszukańcze wprowadzenie w błąd
- Umyślne niewłaściwe postępowanie lub rażące niedbalstwo (zgodnie z prawem niemieckim, §§ 276, 309 BGB)
- Naruszenie istotnych zobowiązań umownych (Kardinalpflichten), ograniczone do przewidywalnych szkód typowych dla tego rodzaju umowy
- Jakąkolwiek inną odpowiedzialność, której nie można wyłączyć lub ograniczyć na mocy obowiązującego prawa

### 10.4 Odpowiedzialność za produkt

Odpowiedzialność na mocy niemieckiej ustawy o odpowiedzialności za produkt (Produkthaftungsgesetz) pozostaje nienaruszona.

---

## 11. Zwolnienie z odpowiedzialności

Zgadzają się Państwo zwolnić z odpowiedzialności, bronić i uchronić Dostawcę, jego partnerów, pracowników i agentów od wszelkich roszczeń, zobowiązań, szkód, strat, kosztów, wydatków lub opłat (w tym uzasadnionych honorariów adwokackich) wynikających z lub związanych z:

- Państwa naruszeniem niniejszych Warunków
- Państwa naruszeniem jakiegokolwiek prawa lub praw stron trzecich
- Państwa korzystaniem z Aplikacji w celu uzyskania dostępu do lub zarządzania infrastrukturą, do której nie są Państwo uprawnieni
- Jakąkolwiek treścią lub konfiguracją tworzoną, modyfikowaną lub usuwaną przez Państwa za pośrednictwem Aplikacji

Obowiązek zwolnienia z odpowiedzialności nie ma zastosowania do konsumentów w rozumieniu obowiązujących przepisów o ochronie konsumentów, jeżeli prawo bezwzględnie obowiązujące zabrania takiego zwolnienia.

---

## 12. Rozwiązanie

### 12.1 Rozwiązanie przez Państwa

Mogą Państwo w każdej chwili rozwiązać niniejsze Warunki, odinstalowując Aplikację ze swoich urządzeń.

### 12.2 Rozwiązanie przez Dostawcę

Dostawca może natychmiast rozwiązać lub zawiesić Państwa licencję na korzystanie z Aplikacji w przypadku istotnego naruszenia niniejszych Warunków. W przypadku rozwiązania:

- Państwa prawo do korzystania z Aplikacji wygasa natychmiast
- Muszą Państwo odinstalować Aplikację ze swoich urządzeń
- Sekcje 6, 9, 10, 11, 13, 14, 16 przetrwają rozwiązanie

### 12.3 Skutek dla zakupu

Rozwiązanie nie uprawnia Państwa do zwrotu zakupu w aplikacji, z wyjątkiem sytuacji wymaganych przez obowiązujące przepisy o ochronie konsumentów lub politykę zwrotów Apple.

---

## 13. Prawo właściwe i rozstrzyganie sporów

### 13.1 Prawo właściwe

Niniejsze Warunki podlegają prawu Republiki Federalnej Niemiec, z wyłączeniem jego norm kolizyjnych oraz Konwencji Narodów Zjednoczonych o umowach międzynarodowej sprzedaży towarów (CISG).

W przypadku konsumentów w Unii Europejskiej / EOG niniejszy wybór prawa nie pozbawia Państwa bezwzględnie obowiązującej ochrony konsumenta wynikającej z prawa Państwa kraju zwykłego pobytu.

### 13.2 Jurysdykcja

W odniesieniu do przedsiębiorców, osób prawnych prawa publicznego oraz publicznoprawnych funduszy specjalnych (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen) wyłącznym miejscem jurysdykcji dla wszystkich sporów wynikających z niniejszych Warunków jest Bad Nauheim, Niemcy.

Dla konsumentów obowiązuje ustawowe miejsce jurysdykcji. Mogą Państwo wnosić sprawy do sądów swojego kraju zwykłego pobytu.

### 13.3 Internetowe rozstrzyganie sporów UE

Komisja Europejska udostępnia platformę internetowego rozstrzygania sporów pod adresem https://ec.europa.eu/consumers/odr.

### 13.4 Arbitraż konsumencki

Dostawca nie jest zobowiązany ani skłonny do udziału w postępowaniach rozstrzygania sporów przed komisją arbitrażową konsumentów (Verbraucherschlichtungsstelle) w rozumieniu niemieckiej ustawy o rozstrzyganiu sporów konsumenckich (VSBG), chyba że wymaga tego prawo.

---

## 14. Postanowienia regionalne

### 14.1 Niemcy

- Prawa konsumenta zgodnie z BGB §§ 312 i nast., §§ 327 i nast. (produkty cyfrowe) pozostają nienaruszone
- Ustawowe prawo odstąpienia zgodnie z BGB § 355 ma zastosowanie, gdzie to właściwe

### 14.2 Unia Europejska / EOG

- Dyrektywa o prawach konsumentów 2011/83/UE oraz dyrektywa o treściach cyfrowych (UE) 2019/770 mają zastosowanie, jeśli są Państwo konsumentem
- Zawiadomienia wymagane na mocy art. 12 aktu o usługach cyfrowych (rozporządzenie (UE) 2022/2065) są zawarte w Nocie Prawnej

### 14.3 Zjednoczone Królestwo

- Consumer Rights Act 2015 ma zastosowanie, jeśli są Państwo konsumentem zamieszkałym w Zjednoczonym Królestwie
- Treści cyfrowe muszą być zadowalającej jakości, odpowiednie do celu i zgodne z opisem

### 14.4 Szwajcaria

- Bezwzględnie obowiązujące przepisy konsumenckie szwajcarskiego Kodeksu Zobowiązań (OR) pozostają nienaruszone
- Federalna ustawa przeciwko nieuczciwej konkurencji (UWG) ma zastosowanie

### 14.5 Stany Zjednoczone

- Niniejsze Warunki nie mają na celu tworzenia praw wynikających ze stanowych ustaw o ochronie konsumentów, które nie mają zastosowania zgodnie z ich treścią
- Mieszkańcy Kalifornii: zawiadomienie o prawach konsumenta zgodnie z Civil Code § 1789.3 — kontakt: moin@berger-rosenstock.de

### 14.6 Kanada

- Quebec Consumer Protection Act ma zastosowanie do mieszkańców Quebecu, gdy jest to obowiązkowe
- Język umowy: niniejsze Warunki są dostarczane w języku angielskim; wersje francuskie są dostępne, gdy wymaga tego Charter of the French Language (Quebec)

### 14.7 Australia

- Gwarancje Australian Consumer Law (Competition and Consumer Act 2010, załącznik 2) mają zastosowanie, jeśli są Państwo konsumentem — gwarancje te nie mogą być wyłączone

### 14.8 Nowa Zelandia

- Consumer Guarantees Act 1993 ma zastosowanie, jeśli są Państwo konsumentem dla osobistego, domowego lub gospodarstwa domowego użytku

### 14.9 Japonia

- Consumer Contract Act (消費者契約法) ma zastosowanie; postanowienia niniejszych Warunków, które byłyby nieważne na mocy tej ustawy, są ograniczone w niezbędnym zakresie

### 14.10 Korea Południowa

- Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률) ma zastosowanie

### 14.11 Brazylia

- Consumer Defense Code (CDC, ustawa nr 8.078/1990) ma zastosowanie; prawa konsumenta nie mogą być zrzeczone

### 14.12 Indie

- Consumer Protection Act 2019 oraz E-Commerce Rules 2020 mają zastosowanie, jeśli są Państwo konsumentem

### 14.13 Pozostałe jurysdykcje

Dla użytkowników w jurysdykcjach nie wymienionych wyżej niniejsze Warunki mają zastosowanie w zakresie dozwolonym przez lokalne bezwzględnie obowiązujące przepisy o ochronie konsumentów.

---

## 15. Prawa konsumenta (obowiązkowe ujawnienia)

Niniejsze Warunki nie wpływają na Państwa ustawowe prawa konsumenta wynikające z obowiązującego prawa, w tym między innymi:

- Dyrektywa UE o prawach konsumentów (2011/83/UE) oraz dyrektywa o treściach cyfrowych ((UE) 2019/770)
- UK Consumer Rights Act 2015
- Australian Consumer Law
- Niemieckie przepisy BGB dotyczące ochrony konsumenta (§§ 312 i nast., §§ 327 i nast.)
- Nowozelandzki Consumer Guarantees Act 1993
- Brazylijski Consumer Defense Code (CDC)
- Kanadyjskie prowincjonalne ustawy o ochronie konsumentów
- Wszelkie inne obowiązujące przepisy o ochronie konsumentów w Państwa jurysdykcji

---

## 16. Postanowienia ogólne

### 16.1 Zmiany niniejszych Warunków

Możemy od czasu do czasu aktualizować niniejsze Warunki. Istotne zmiany będą komunikowane poprzez Aplikację lub wpis w App Store co najmniej trzydzieści (30) dni przed ich wejściem w życie. Dalsze korzystanie po wejściu w życie zmian stanowi ich akceptację.

### 16.2 Cesja

Nie mogą Państwo cedować ani przenosić niniejszych Warunków ani żadnych praw z nich wynikających bez uprzedniej pisemnej zgody Dostawcy. Dostawca może dokonać cesji niniejszych Warunków w związku z fuzją, przejęciem lub sprzedażą aktywów.

### 16.3 Rozdzielność postanowień

Jeżeli którekolwiek postanowienie niniejszych Warunków zostanie uznane za niewykonalne lub nieważne, postanowienie to zostanie ograniczone lub wyeliminowane w minimalnym koniecznym zakresie, tak aby pozostałe Warunki pozostały w pełnej mocy. Dla prawa niemieckiego zastosowanie ma § 306 BGB.

### 16.4 Zrzeczenie się

Niewyegzekwowanie przez Dostawcę któregokolwiek postanowienia niniejszych Warunków nie stanowi zrzeczenia się tego postanowienia.

### 16.5 Całość porozumienia

Niniejsze Warunki, wraz z Polityką Prywatności, Notą Prawną oraz Apple EULA, stanowią całość porozumienia między Państwem a Dostawcą w odniesieniu do Aplikacji i zastępują wszelkie wcześniejsze umowy i ustalenia.

### 16.6 Język

Wiążącą wersją niniejszych Warunków jest wersja angielska. Tłumaczenia są dostarczane dla wygody. W przypadku rozbieżności pierwszeństwo ma wersja angielska, chyba że bezwzględnie obowiązujące prawo lokalne stanowi inaczej.

### 16.7 Komunikacja elektroniczna

Wyrażają Państwo zgodę na otrzymywanie wymaganych prawnie zawiadomień od Dostawcy w formie elektronicznej (poprzez Aplikację lub e-mail).

### 16.8 Siła wyższa

Dostawca nie ponosi odpowiedzialności za niewykonanie lub opóźnienie w wykonaniu spowodowane zdarzeniami poza jego uzasadnioną kontrolą, w tym siłą wyższą, wojną, terroryzmem, niepokojami społecznymi, sporami pracowniczymi, awariami internetu, przerwami w usługach stron trzecich lub działaniami rządowymi.

---

## 17. Kontakt

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Niemcy
E-mail: moin@berger-rosenstock.de
Numer VAT: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Wszelkie prawa zastrzeżone.
