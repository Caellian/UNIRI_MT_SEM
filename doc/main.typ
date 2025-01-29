#import "template/template.typ": config, figure-list, appendix

#import "@preview/cetz:0.3.1": canvas, draw
#import "@preview/cetz-plot:0.1.0": plot, chart

#show "TODO": box(fill: red, outset: 2pt, text(fill: white, weight: "black", "NEDOSTAJE SADRŽAJ"))

#show: config(
  "seminar",
  class: "Multimedijske Tehnologije",
  "Ray Tracing",
  "Tin Švagelj",
  attributions: [
    *Voditelj kolegija:* doc. dr. sc., Miran Pobar
  ],
  bibliography-file: "references.bib"
)

= Uvod

Metoda praćenja zraka svjetlosti (engl. _ray tracing_, RT) se zasniva na relaksaciji problema simulacije ponašanja svjetlosti u zatvorenom optičkom sustavu. Ray tracing metode nastoje provesti idealnu simulaciju ponašanja svijetla kako bi postigle rezultate bliske stvarnima.

== Motivacija

Autor je odabrao ovu temu za seminar jer unatoč nekom osnovnom znanju u principu rada ray tracing algoritama nije nikada ručno implementirao ray tracing algoritam te je imao loš uvid u stvarnu složenost implementacije. Velik dio te složenosti zapravo uvodi arhitekturiranje pogona za iscrtavanje (engl. _rendering engine_) kada se koriste apstraktna sučelja za programiranje (engl. _abstract programming interface_, API) grafičkih kartica (engl. _graphics card_/_graphics processing unit_, GPU) poput Vulkana, OpenGLa, DirectXa ili Metala.

== Povijest razvoja

Prvi temelj ovog algoritma je objavio P. W. Ford 1960. godine u radu "Nova shema praćenja zraka svjetlosti" (engl. _"New Ray Tracing Scheme"_), a bazirao ga je na jednadžbama koje je H. A. Buchdahl laboratorijski testirao i opisao u monografiji "Koeficijenti optičke aberacije" (engl. _"Optical Aberration Coefficients"_).

Fordov algoritam je bio osmišljen za aksijalno simetrične optičke sustave te je baratao s "idealnim zrakama svjetlosti" koje ne prate stvarne zakone refrakcije svijetla nego paraksijalnu optiku koja dopušta linearne aproksimacije refrakcije. Uporaba parakoničnih koordinata je pojednostavilo matematičku analizu, te pružilo iznimno brzu metodu izračuna za sustave koji sadrže isključivo sfere. @ford1960new

Kroz narednih 20 godina je bilo nekoliko manjih pomaka, no zbog hardverskih ograničenja je ova tehnika vidjela značajan napredak tek sredinom 80ih godina (20. st.), kada je na Siggraphu i drugim manjim konferencijama, kao i u akademiji bilo objavljeno preko 150 različitih radova, članaka i prezentacija na temu. #linebreak()
Mnoge od tih tehnika su i danas primjenjive, no zbog tadašnjih hardverskih ograničenja su bile primarno korištene za prijevremen (engl. _offline_) prikaz.

Nvidia je 2020. godine objavila Ampere seriju grafičkih kartica (engl. _graphics processing unit_, GPU) za radne stanice (profesionalna primjena) @rtx-launch koje imaju specijalizirane hardverske komponente za određene izračune koji su opisani u @hw-support, te nedugo zatim i komercijalnu seriju RTX grafičkih kartica. Te kartice su omogućile provođenje jednostavnijih ray tracing algoritama u realnom vremenu (engl. _online_).

#pagebreak()
= Hardverska podrška <hw-support>

Prethodno specijaliziranom hardveru, ray tracing metode su funkcionirale tako što se na zaslonu prikazao običan kvadrat koji pokriva cijelu površinu pogleda, vertex shader bi služio samo za prosljeđivanje podataka fragment shaderu, a fragment shader bi bio zadužen za simulaciju zraka, izračun i akumulaciju podataka koji su pruženi uzorkovanjem zraka koje su pridružene individualnim pikselima.

#"2002." godine su Jörg Schmittler, Ingo Wald i Philipp Slusallek demonstrirali prednost uporabe specijaliziranog hardvera za provjeru intersekcija zraka sa geometrijom sadržanoj u sceni (engl. _scene geometry_, nadalje geometrija scene ili geometrija). @schmittler2002saarcor
@saarcor prikazuje primjer takve jezgre za koračanje zrakom svjetlosti (engl. _Ray Tracing Core_, engl. _RT Core_, RT jezgra)

#figure(caption: [SaarCOR kao primjer RT jezgre. Izvor: @schmittler2002saarcor],
  image("./figure/rt_architecture.svg")
) <saarcor>

Arhitektura modernih RT jezgri nije značajno različita u funkcionalnosti koju pruža, pa je @saarcor dovoljna aproksimacija za ovaj seminarski rad. Ostatak seminarskog rada pretpostavlja uporabu RT jezgri grafičke kartice, ili u kontekstu objašnjenja praktičnog dijela prijevremen prikaz putem procesora (engl. _central processing unit_, CPU).

Uz specijaliziran hardver su u Vulkan, D3D12 i Metal dodana proširenja koja omogućuju njegovu uporabu.

Ta proširenja generalno dodaju:
- strukture i funkcije za prijenos podataka o geometriji (trokutima ili AABB okvirima) i zrakama,
- programabilno sučelje za provođenje testiranja presjeka zraka s geometrijom u sklopu programa provedenom na grafičkoj kartici (engl. _shader_),
  - fazu obrade zaprimljenih podataka na grafičkim karticama.

#pagebreak()
= Temeljni način rada

Temeljno razlikujemo algoritme koji koračaju zrakama svjetlosti unaprijed ili unazad. Pravilan odabir algoritma ovisi o području primjene. Za svrhu prikaza računalne grafike namijenjene zabavi su algoritmi koračanja zrakama unazad bolji izbor jer točnost nije bitna.

== Koračanje unaprijed

Koračanje zrakama unaprijed je vjerodostojno stvarnom ponašanju svjetlosti u prirodi, no jako je potrošan za svrhu grafičkog prikaza jer većinu odaslanih zraka svjetlosti apsorbiraju predmeti u sceni ili se dovoljno udalje da više nemaju značajan utjecaj na rezultat prikaza, te nisu vidljivi kao što je primjetno na @fw-image[slici].

#figure(caption: "Zrake svjetlosti odaslane iz izvora", image("art/forward.svg")) <fw-image>

Apsorbirana svjetlost ima fizičke manifestacije na tijela poput uzbuđenja elektrona i zagrijavanja tvari, pa je za određene namjene (npr. fizičke simulacije @Qin:12) ovaj pristup jedino smislen.

== Koračanje unazad 

Koračanje zrakama unazad se razlikuje od prethodno opisanog pristupa po tome što ne simulira zrake svjetlosti nego unazadno uzorkuje osvjetljenje sa scene odašiljajući zrake uzorkovanja (nadalje zrake) iz kamere kao što je prikazano na @bw-image[slici].

#figure(caption: "Zrake uzorkovanja odaslane iz kamere", image("art/backward.svg")) <bw-image>

#pagebreak()
@ray-image prikazuje shematski prikaz principa rada unazadnog koračanja zrakama. Unazadni RT algoritam treba:
1. stvoriti jednu ili više zraka kojima će boja svakog piksela prikaza biti uzorkovana:
  - pozicija svake zrake je jednaka poziciji kamere, a smjer zrake ovisi o vrsti projekcije, leći kamere, te poziciji piksela kojem je zraka pridružena,
2. prolaskom kroz predmete u sceni, pronaći najbliži kameri kojeg zraka dodiruje,
3. provesti prikladnu interakciju zavisno o materijalu,
  - ako se radi o reflektivnom materijalu ponoviti uzorkovanje od 1. koraka za uzorkovanu točku kako bi se odredila reflektirana svjetlost ($L_i$),
    - ako se radi o nesavršenom zrcalu, potrebno je uzorkovati nekoliko zraka, pa zatim
4. pohraniti uzorkovanu vrijednost (ili težinski prosjek više njih) u međuspremniku (engl. _buffer_) za prikaz.

#figure(caption: "Pronalaženje presjeka zraka s tijelima", image("figure/rayfiltering.png")) <ray-image>
// Originalna vektorska grafika ima apsurdan broj elemenata jer je dijelom stvorena u blenderu, pa je uključena rastersizirana verzija zbog bržeg crtanja, iako je nešto veća


#pagebreak()
= Geometrija scene

Određivanje presjeka zrake s geometrijom ovisi o načinu na koji je geometrija scene definirana. Geometrija scene može biti definirana pravilima ili diskretnim podacima.

I kontekstu računalne grafike su diskretni podaci češći i njihova je primjena proširenija jer pravilima zadan oblik često zahtijeva veću razinu truda za postizanje rezultata koji su neprimjetno bolji od diskretnih za mnoge vrste primjena.

Pravilima zadana geometrija zauzima manje prostora za pohranu kod jednostavnih geometrijskih tijela poput sfera, cilindara, diskova, stožaca i dr. pa je njena primjena bolja za takve slučajeve. Slaganjem različitih jednostavnijih tijela se mogu postići puno složeniji oblici korištenjem Booleovih operatora (engl. _boolean operators_), no neke iznimno nepravilne površine je i dalje teško ispravno prikazati na ovaj način pa je diskretna geometrija često jednostavniji odabir. Iako se svako tijelo može izraziti pravilima, diskretan način pohrane može biti znatno jednostavniji za izračun od rješavanja iznimno složenih jednadžbi za svaki presjek zrake s geometrijom (ali i provjeru sudara).

Praktični dio ovog seminarskog rada koristi pravilima zadanu sferu koja je prikazana u priloženom @ray-sphere-intersection[kȏdu], jer je provjera kolizije, te udaljenosti kolizije zrake sa sferom jednostavna.

#figure(caption: "Provjera kolizije zrake sa sferom i udaljenosti kolizije")[
  ```rust
  pub struct Sphere {
    pub pos: Vec3,
    pub radius: f32,
  }

  impl Intersect<Ray> for Sphere {
    type Result = f32;

    fn intersect(&self, ray: &Ray) -> Option<f32> {
      let direction = ray.origin - self.pos;
      let ray_magnitude_squared = ray.direction.length_squared();
      let alignment = 2.0 * direction.dot(ray.direction);
      let max_travel = direction.length_squared() - self.radius * self.radius;
      let discriminant_squared = alignment * alignment - 4.0 *
                                 ray_magnitude_squared * max_travel;

      if discriminant_squared > 0.0 {
        let discriminant = discriminant_squared.sqrt();
        let t1 = (-alignment - discriminant) / (2.0 * ray_magnitude_squared);
        if t1 > 0.0 {
          return Some(t1)
        }
        let t2 = (-alignment + discriminant) / (2.0 * ray_magnitude_squared);
        if t2 > 0.0 {
          return Some(t2)
        }
      }

      None
    }
  }
  ```
] <ray-sphere-intersection>

Kod provjere presjeka je za složenije scene s mnogo geometrije ili složenom geometrijom praktično koristiti akceleracijske strukture za obilazak sadržajem scene (engl. _scene traversal acceleration structures_). Česte su primjene hijerarhije omeđujućih volumena (engl. _bounding volume heirarchy_, BVH) i Kd-stabla (engl. _Kd-tree_) jer dopuštaju potpuno izbjegavanje zahtjevnih izračuna za kolizije. @Pharr2016-ex[dio 4.]

Provjerom kolizija se može grubo iscrtati sadržaj scene kao što je prikazano za sferu u @step-1[slici].

#figure(caption: "Prikaz zraka koje presijecaju sferu (bijelo) i koje ne (crno)", image("figure/step_1.png", height: 10em)) <step-1>

= Svijetlo, boje i kolorimetrija

U fizičkom smislu, svjetlost se može razmatrati istovremeno kao val elektromagnetskog zračenja i skup kvantnih čestica koje nazivamo fotonima. Drugi oblik je jednostavniji za simulaciju pa se pretpostavlja u kontekstu RT algoritama i ovom seminarskom radu. Bitna karakteristika fotona je njegova *valna duljina* (engl. _wavelength_).

Kada razmatramo skup fotona u jednom snopu svjetlosti, grupiramo sve valne duljine u njemu sadržanih fotona u *spektar valnih duljina* (engl. _wavelength sprectrum_), a brojnost fotona pojedinih valnih duljina predstavlja intenzitet radijacije (engl. _radiation intensity_) za tu valjnu duljinu koji je izražen kao $(mu"mol")/(m^2s)$, tj. broj $10^6$ fotona koja prođu kroz površinu od $1m^2$ u jednoj sekundi.

Spektar valnih duljina utječe na percipiranu boju svjetlosti ako se nalazi u rasponu od 400nm do 700nm.

U kontekstu RT aplikacija, boje mogu biti pohranjene kao zrake svjetlosti kada je željena točnija simulacija, no za svrhe prikaza modela, u računalnim igricama i animaciji su češće pohranjenje *diskretno* u prostoru boja spremnom za prikaz poput sRGB.

#"1931." godine je internacionalna komisija za osvjetljenje (fr. _Commission internationale de l'éclairage_, CIE) formirala prostor boja (engl. _color space_) koji opisuje kako "standardni promatrač" (engl. _"standard observer"_) vidi različite nijanse boja u vezi s podražajima fotoosjetljivih receptora ljudskog oka. Taj prostor boja je utemeljen na mjerenjima koja su proveli William David Wright i John Guild 1920-ih godina, i zove se XYZ.

@color-mapping prikazuje preslikavanje valnih duljina svjetlosti u XYZ prostor boja.

#let cie-dse = csv("data/cie-cmf.csv").map(it => {
  (int(it.at(0)), float(it.at(1)), float(it.at(2)), float(it.at(3)))
})

#figure(caption: [
  CIE funkcije za preslikavanje valne duljine u XYZ. Izvor: @Smith1931-qs
],
canvas({
  plot.plot(
    size: (12, 5),
    x-tick-step: 50,
    y-tick-step: 0.5,
    y-max: 2,
    x-max: 725,
    x-label: $lambda "[nm]"$,
    y-label: none,
    y-grid: "both",
    legend: "inner-north-east",
  {
    plot.add(cie-dse.map(it => {
      (it.at(0), it.at(1))
    }), style: (stroke: red), label: $overline(x)(lambda)$)
    plot.add(cie-dse.map(it => {
      (it.at(0), it.at(2))
    }), style: (stroke: green), label: $overline(y)(lambda)$)
    plot.add(cie-dse.map(it => {
      (it.at(0), it.at(3))
    }), style: (stroke: blue), label: $overline(z)(lambda)$)
  })
})) <color-mapping>

Iako je udaljen od načina na koji se boje često predstavljaju u digitalnom obliku (sRGB), ima prednost jer može u potpunosti opisati cijeli spektar boja koje ljudsko oko vidi. Zbog toga se koristi za predstavljanje boja u aplikacijama kod kojih je bitno da mogu ispravno upravljati bojama koje će kasnije biti prikazane korisniku.

Za jednostavnije RT algoritme je diskretan način predstavljanja boja praktičniji za uporabu jer zauzima manje prostora (4B po zraci) i zahtjeva manje izračuna prilikom interakcija, naspram pohrane realističnih podataka o zrakama koji imaju veće zahtjeve (ovisno o razlučivosti pohranjenog spektra).

No postoje primjene gdje je neophodno koristiti realističnu reprezentaciju jer daje puno točnije rezultate. Ona je neizbježna za točnu simulaciju:
- interakcije svijetla s prizmama koje drugačije usmjeravaju svjetlost ovisno o njenoj valnoj duljini (disperzija),
- interakcije svijetla s materijalima koji drugačije apsorbiraju i/ili fluoresciraju svjetlost različitih valnih duljina.

Pretvorba iz XYZ prostora boja u sRGB prostor se provodi jednostavnom linearnom transformacijom koja je prikazana u @xyz-to-rgb[kodu]. Memoizacijom je moguće izbjeći potrebu za učestalim izračunom u svrhu pretvorbe boja.

#figure(caption: "Pretvorba XYZ boja u sRGB")[
```rust
static CIE_TO_RGB: Mat3 = Mat3::from_cols_array(&[
   3.2406255, -0.9689307,  0.0557101,
  -1.537208,   1.8757561, -0.2040211,
  -0.4986286,  0.0415175,  1.0569959,
]);

impl From<CieXyz> for SrgbU8 {
  fn from(value: CieXyz) -> Self {
    let result: Vec3 = CIE_TO_RGB * Into::<Vec3>::into(value);
    SrgbU8 {
      r: (result.x * 255.) as u8, g: (result.y * 255.) as u8,
      b: (result.z * 255.) as u8, a: (value.a * 255.) as u8,
    }
  }
}
```
] <xyz-to-rgb>

Od inicijalne valne duljine je dobivena XYZ boja linearnom interpolacijom susjednih vrijednosti iz tablice preslikavanja prikazanoj u @color-mapping[slici].

Konačno, množenjem intenziteta zrake s XYZ bojama se dobivaju vrijednosti koje je potrebno normalizirati za prikaz. Dinamički raspon (engl. _dynamic range_) uzorkovanih boja boja će biti veći nego što simulirani senzor kamere može uhvatiti, i također veći nego što je moguće prikazati na zaslonu.

= Kamera

Senzor, leća i otvor koje kamera koristi igraju značajnu ulogu u konačnom prikazu slike.

Senzor utječe na kvalitete slike u koje ubrajamo:
- razlučivost (engl. _resolution_),
- dinamički raspon,
- dubinu boja (engl. _color depth_),
- razinu šuma (engl. _noise_) u okruženjima niskog osvjetljenja,
- vidno polje (engl. _field of view_, FoV), i dr.

Leća, kao i njena udaljenost od sensora utječu na:
- vidno polje,
- dubinsku oštrinu (engl. _depth of field_, DoF),
- aberacije boje (engl. _chromatic aberrations_),
- distorzije, i
- druge karakteristike.

Aparatura (engl. _aperture_) kontrolira i utječe na:
- duljinu ekspozicije (engl. _exposure_),
- vinjetu (engl. _vignette_),
- boke (jap. ぼけ, _boke_),
- uvećanje, i
- druge karakteristike.

Može se također koristiti i kamera s otvorom malog radiusa (engl. _pinhole camera_), koja daje zamućeniju sliku s izraženom vinjetom.

RT algoritmi mogu uzeti sve te karakteristike kamere u obzir kako bi izmijenili način na koji je scena prikazana, no pretežno se modelira samo nekolicina njih. Zbog jednostavnosti je u praktičnom dijelu ovog seminara korištena statična scena i idealna kamera u perspektivi s vidnim poljem horizontalnog raspona od $90 degree$. Korištena kamera također ne prati duljinu ekspozicije, nego se pretpostavlja da su svi fotoreceptori senzora osvijetljeni istovremeno konstantnom jačinom svjetlost.

= Materijali

Izgled materijala geometrije u sceni ovisi o brojnim svojstvima samog materijala kao i mediju u kojem se on i kamera nalaze.

Potpuno ispravna simulacija interakcije zraka svjetlosti s materijalima je nepraktična jer su mjerenja nekih svojstva materijala iznimno spor proces koji zahtjeva skupu opremu. Također, određena svojstva nije moguće dobro izmjeriti za neke materijale pa je potrebno koristiti aproksimacije. Simulacije koje se oslanjaju na veliku količinu svojstva materijala također zahtijevaju vrlo snažnu opremu i/ili puno vremena.

Iz tih razloga se za RT u realnom vremenu nastoji pojednostaviti ključna svojstva koja imaju utjecaj na konačan izgled materijala na osnovne koje značajno pridonose konačnom izgledu. Također, materijale se grupira ovisno o njihovom generalnom izgledu (mat, plastični, ...) kako bi se daljnje pojednostavio izračun.

Osnovna svojstva materijala mogu biti:
- osnovna/albedo boja,
- metaličnost površine,
- gruboća/hrapavost površine,
- indeks refrakcije za spekularnu refleksiju i refrakciju,
- prozirnost,
- svojstva hoda prilikom raštrkavanja svjetlosti u materijalu,
- boja emisije,
- boja i debljina obloga (engl. _film_), no i
- neka druga.

U praktičnom dijelu rada nisu korišteni materijali te je pretpostavljeno da je površina 2-sfere savršeno ogledalo.

== Teksture

Materijali često nemaju uniformna svojstva po svojoj cijeloj površini (npr. boja, hrapavost, ...). Iz tog razloga je poželjno složiti RT algoritam koji dopušta upravljanje individualnim svojstvima materijala pomoću tekstura.

= Izvori i interakcije svjetlosti

Svijetlo je emitirano (engl. _emission_) iz izvora. U grafici to aproksimiramo idealnim reprezentacijama svjetlosti, no u stvarnosti svijetlo emitiraju različiti materijali pod utjecajem nekih kemijskih ili fizičkih procesa.

U svrhu pojednostavljivanja simulacije, koriste se 3 osnovna izvora svjetlosti:
- točkasti izvor (engl. _point light_),
- usmjereni izvor (engl. _directional light_), i
- ambijentno osvjetljenje (engl. _ambient light_).

U nekim slučajevima se može modelirati i reflektor, no on je specijalizirana verzija točkastog izvora koji ima ograničen smjer emisije na neki zadani kut, te ponekad prigušenje prema rubovima.

Kod unazadnih RT algoritama se dio geometrije smatra neosvijetljenim ako putanja uzoraka ne završava u izvoru svjetlosti. Konačno osvjetljenje za neosvijetljene dijelove scene je ambijentalno (ako se koristi).

U stvarnosti ambijentalno osvjetljenje ne postoji nego je ono proizvod indirektne svjetlosti obližnjih izvora ili sunca. No postizanje ambijentalnog osvjetljenja na taj način nije praktično jer bi zahtijevalo glomazan broj rekurzija algoritma što bi učinilo RT nepraktično sporim.

Usmjereni izvori se skoro nikada ne pojavljuju u prirodi, no u računalnoj primjeni se koriste za izvore svjetlosti koji su dovoljno udaljeni od sjenčane geometrije scene da su emitirane zrake svjetlosti gotovo paralelne. Zbog ograničenja hardvera, tj. pohrane decimalnih bojeva i pogrešaka pri računu s iznimno malim ili velikim vrijednostima istih, modeliranje vrlo dalekih izvora svjetlosti ne bi davalo točne rezultate.#linebreak()
Usmjereni snop svjetlosti se može postići jedino uz pomoć polarizacijskih filtera ili stimuliranom emisijom (npr. laseri).

Točkasti izvor svjetlosti je najbliži stvarnim (spontanim) izvorima, iako stvarni izvori ne emitiraju svjetlost istog intenziteta u svim smjerovima s iste pozicije.

U praktičnom dijelu je modeliran usmjereni izvor koji je opisan jednostavno vektorom smjera.

== Refleksija

Zbog toga što na svaku uzorkovanu točku može djelovati svjetlost iz različitih smjerova, za svaku uzorkovanu točku je (u idealnoj implementaciji) potrebno rekurzivno uzorkovati dolazeću svjetlost ($L_i$) iz svih točaka koje čine površinu jedinične sfere $cal(S)_2$ centrirane oko točke presjeka prethode zrake s geometrijom. Kada je materijal neproziran ili je od interesa samo refleksija, dovoljno je uzorkovati polusferu ($cal(H)_2$) čija ravna stranica je tangenta na površinu, a zakrivljena je udaljenija od ravne.

Formula za izračun konačnog osvjetljenja koje je vidljivo u nekoj točki je:
#figure(caption: [
  Formula za izračun reflektirane svjetlosti točke @Pharr2016-ex[str. 350]
], $
L_0(p, omega_0) =
  underbrace(L_e (p, omega_0), "emitirani sjaj") +
  integral_(cal(H)^2)
    underbrace(f(p, omega_0, omega_i), "BRDF")
    underbrace(L_i (p,omega_i), "dolazeći sjaj")
    |cos(theta_i)|
    d omega_i
$) <osvjetljenje>

gdje je:
- $p$ neka obasjana točka koju promatramo,
- $omega_0$ fazor koji označava smjer iz kojeg je točka $p$ promatrana,
- $L_0 (p, omega_0)$ ukupan sjaj koji napušta točku $p$ u smjeru $omega_0$ (engl. _outgoing radiance_),
- $L_e (p, omega_0)$ sjaj kojeg sam materijal emitira (engl. _emitted radiance_) u smjeru $omega_0$,
- integral $integral_(cal(H)^2)..d omega_i$ djeluje kao *težinski zbroj vrijednosti podintegralnog umnoška* za sve smjerove $d omega_i$ iz kojih može doprijeti svjetlost. Integrira po površini jedinične 2-polukugle $cal(H)^2$, te se sastoji od:
  - $f(p, omega_0, omega_i)$ dvosmjerne funkcije distribucije refleksije i transmisije (engl. _Bidirectional Reflectance Distribution Function_, BRDF),
  - $L_i (p,omega_i)$ je sjaj koji dolazi u točku $p$ od drugih izvora svjetlosti (engl. _incoming radiance_), te odbijanjem od reflektivnih površina, te konačno
  - $|cos(theta_i)|$ je geometrijsko prigušenje (engl. _geometric attenuation_) koje osigurava da je svjetlost koja se reflektira u smjeru $omega_0$ najizraženija za savršeni kut refleksije a smanjuje se za pliće kuteve.

Jer je uzorkovanje svih mogućih zraka koje pridonose osvjetljenju nemoguće (jer ih je beskonačno mnogo), koriste se Las Vegas ili Monte Carlo aproksimacije za određivanje podintegralnog izraza. Ove aproksimacije pojednostavljuju problem određivanja stvarne vrijednosti integrala na određivanje nasumično odabranih uzoraka. @Pharr2016-ex[dio 13.]

U kontekstu određivanja dolazeće svjetlosti se koristi tehnika koja se zove "ruski rulet". Kod ruskog ruleta, uzorkuje se nekoliko zraka svjetlosti umjesto svih zraka (za cijelu jediničnu 2-sferu) te pridonos "pobjedničkih" zraka dijeli s $1-P$, gdje je $P$ vjerojatnost da će promatrana zraka biti otklonjena iz izračuna. @Pharr2016-ex[dio 13., str. 787]

Dobro je za "nasumično odabrane" zrake za daljnji hod odabrati zrake s manjim geometrijskim prigušenjem (sličnog smjera kao zraka savršene refleksije), jer će one generalno dati bolju aproksimaciju dolazeće svjetlosti.

@refl-code prikazuje izračun korišten za određivanje vrijednosti uzoraka na 2-sferi koja je savršeno zrcalo.

#figure(caption: "Izračun refleksije")[
```rust
let target = ray.source.expect("camera ray must have target");

if let Some(distance) = sphere.intersect(&ray) {
  let hit_point = ray.origin + (ray.direction * distance);
  let normal = (hit_point - sphere.pos).normalize();
  let light_intensity = normal.dot(directional_light).max(0.0);

  let color = (255.0 * light_intensity) as u8;
  img.put_pixel(target.x, target.y, Rgb([color, color, color]));
} else {
  img.put_pixel(target.x as u32, target.y as u32, Rgb([0, 0, 0]));
}
```
] <refl-code>

Konačan prikaz praktičnog rada je prikazan u @final[slici].

#figure(caption: "Konačan prikaz", image("figure/output_1.png", width: 30em)) <final>

#pagebreak()
= Otklanjanje buke/šuma

Kod RT algoritama je osim u najjednostavnijim slučajevima potrebno provesti otklanjanje buke/šuma (engl. _noise_). Buka je rezultat korištenja Monte Carlo/Las Vegas aproksimacija koje uvode nasumičnost uzorkovanja u svrhu ubrzanja izračuna. Radi se o velikom nedostatku ovog načina prikaza grafike kojeg je u principu moguće samo mitigirati uporabom brojnih algoritmi za poboljšavanje rezultata ili provođenjem dovoljno/vrlo velikog broja uzoraka gdje ta buka postaje manje primjetna.

U zadnje vrijeme počinju se primjenjivati tehnike iz strojnog učenja u svrhu otklanjanja buke kako bi se ona otklonila blizu realnog vremena.

#figure(caption: [Prikaz rezultata prije i nakon uklanjanja buke. Izvor: @mara17towards], image("figure/noise.png"))


#pagebreak()
= Usporedba s klasičnom rasterizacijom

Zbog duge primjene, za klasične metode rasterizacije (nadalje rasterizacija) je razvijen velik broj tehnika za postizanje različitih efekata koji su primjetni u stvarnosti. Mnogi od tih efekata su nešto jednostavniji za postignuti uporabom RT algoritama no zbog toga su zahtjevniji za provođenje. 

== Odrazi

Odrazi (engl. _reflections_) se u klasičnim metodama rasterizacije izvode tako da se scena prije rasterizacije glavnog prikaza prvobitno prikaže s pozicije koja je zrcaljena pozicija kamere s obzirom na reflektivnu površinu. Ovisno o sadržaju scene, ova tehnika može biti iznimno zahtjevna, pogotovo kada je u istom kadru vidljivo više reflektivnih površina. U nekim slučajevima je moguće provesti prikaz pomoću trikova poput rekreacije zrcaljenog sadržaja scene unutar/iza ogledala što značajno umanjuje ili potpuno otklanja zahtjevnost dodatnog prikaza jer je zaseban prikaz (engl. _render pass_) potreban samo ako ogledalo treba sadržavati dinamične dijelove scene koji nisu unaprijed poznati.

== Ambijentalna okluzija

Ambijentalna okluzija (engl. _ambient occlusion_, AO) se pojavljuje kada geometrija sadrži kuteve manje od $180 degree$, a postaje zamjetljivija kod oštrijih kutova. @ssao prikazuje istu scenu s (a) i bez (b) AO - vidi se zamjetna razlika u kvaliteti prikaza zbog dobivenih osjećaja dubine.

Kod rasterizacije je ambijentalna okluzija u prostoru zaslona (engl. _screen-space ambient occlusion_, SSAO) tehnika koja daje iznimno uvjerljive rezultate a usporedno je jeftinija od njoj prethodećih tehnika koje su koristile stvarnu geometriju scene. @learnopengl[SSAO]

#figure(caption: [Usporedba scene sa i bez ambijentalne okluzije. Izvor: @learnopengl[SSAO]], box(width: 25em, columns(2, gutter: 0.2em)[
  #image("figure/ssao_off.png", height: 14em)
  (a) bez SSAO
  #colbreak()
  #image("figure/ssao_on.png", height: 14em)
  (b) sa SSAO
])) <ssao>

SSAO tehnika ima nedostatak što je ne razumije svojstva materijala geometrije na koju je primjenjena. Zbog toga i reflektivne površine dobivaju jednake sjene okluzije iako su one u stvarnosti manje izražene jer reflektivni kutovi "zarobe" manje svjetlosti.

Kod RT tehnika se ambijentalna okluzija pojavljuje prirodno primjenom #link(<osvjetljenje>)[formule za refleksiju (1)] ako površina nije savršeno zrcalo. No za tupe kutove može zahtjevati značano povečanje broja uzoraka.

== Sjene

Sjene se u rasterizaciji se mogu postignuti na mnogo različitih načina ovisno o željenoj kvaliteti, i oni variraju u algoritamskoj složenosti, količini utrošene radne memorije, i drugim karakteristikama. Jedan od klasičnih pristupa je prije glavnog prikaza, prikazati scenu iz perspektive svakog od izvora svjetlosti te pohraniti dubinu svih tijela koja mogu bacati sjenu u zaseban spremnik dubine (engl. _depth buffer_) te ih  potom koristiti pri konačnom prikazu za prikaz tamnije sjenčanje fragmenata koji su u sjeni. @Dlab2022

Nedostatak ovog pristupa je što zahtjeva iznimno veliku rezoluciju spremnika dubine kako bi sjene za predmete koji su udaljeniji od izvora svjetlosti izgledale dobro. Također, potreban je dodatan trud kako bi se osiguralo da sjene ispravno postaju zaglađenije što su udaljenije od geometrije koja ih baca (ili oštrije-bliže).

U slučaju RT algoritama se radi o jednostavnijoj značajki za implementaciju - potrebno je povećati broj uzoraka kako bi se postigao bolji izgled sjena na rubovima. Tu je korisno koristiti RT algoritam koji dopušta promjenjiv broj zraka za određene dijelove scene.

= Zaključak

Iako ray tracing metode pružaju mnoga unaprijeđenja u realizmu prikazanih scena, nisu "čaroban metak"#footnote[rješenje koje ne treba alternative jer zadovoljava sve moguće slučajeve primjene]. Njihova implementacija zahtjeva iznimno puno truda kako bi se pokrile sve namjene, te postoji puno mjesta gdje je potrebno .

#pagebreak()
