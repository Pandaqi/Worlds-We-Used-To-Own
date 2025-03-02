*PRIORITY LIST*

*FATAL ISSUES / PRIORITY*

-   STACK OVERFLOW still happens. I suspect it has something to do with the baby switching regions all the time/wrongly. It sometimes happens when two bunnies are building at the same time, it always happens when one of those is a baby bunny.

    -   ISSUE: Baby bunnies sometimes randomly speed up (make a huge jump, very quickly).

-   NOPE crashes still happen. Does it have something to do with COULDN'T FIND NATURE WITH ID?!

-   WORLD GENERATION sometimes makes a mistake with locations not being found (perhaps a region is so small it doesn't have room for any locations?). Also, sometimes connection lines are generated incorrectly.

*TO DO*

-   Create different plants with different properties

    -   Seeds that keep track of which plant they represent.

    -   (And leafs that do the same?)

    -   These plants should also look and grow differently.

    -   At least we need plants with healing properties, and plants that provide lots of food.

-   DYNAMIC trees and stones and bushes!

    -   But how?

    -   Also, I'd like them to calmly "sway" in the wind

-   Make meat from corpses edible

    -   Create a way to save whether an animal is herbivore, carnivore, or both.

    -   Use that to determine what is food, and what to do on arrival at a certain object

    -   Make corpses lose health, and disappear when completely out of meat.

    -   Also make corpses deteriorate over time.

    -   Find better way to calculate meat content of corpses

-   Make different seasons.

    -   Make weather type depend on season

    -   Make weather type affect plant growth (and animal health? Not sure about that one)

    -   Change the look of plants/trees/etc. during different seasons

*BUILDINGS*

-   "Farm": Displayed with a low fence around the region? Or simply a pole/small building somewhere in the region? Bunnies assigned to it will plant seeds, collect new ones, plant them, and so forth until you tell them to stop.

-   "Training Center": Displayed with some sort of workbench, or perhaps a "training arena", or even better a watchtower/wall. Bunnies assigned to it will get a weapon (if available), and will stay in that region and train.

-   "Special building": ??

Hoe kan ik de buildings interessanter en unieker maken? Dit lijkt me vrij standaard/saai.

*Artificial Intelligence*

-   Introduce some sort of \"dumbness\" parameter to set the difficulty. This can also be used to make the player \"extremely dumb\", because he has to do everything himself.

-   Start with computers creating new offspring, exploring new regions, and conquering them if possible.

*ISSUES AND IDEAS*

-   ISSUE: Still weird things happening with the very first path of pathfind

-   ISSUE: Heel soms gaat er iets mis met het berekenen van de connection lines naar neighbours. Voor nu haal ik de verkeerde lines weg, en als het toch nog fout gaat, doe alles opnieuw. Maar dat kan natuurlijk niet in het uiteindelijke spel.

-   Naar voren/terug springende beesten bij het vechten.

-   Voorpoot en hoofd animatie nog wat stroefjes, maar daar kan ik eigenlijk weinig aan doen.

-   Zorg dat switchregion een beetje slack heeft, zodat we niet steeds switchen als we op de rand lopen (?)

-   Check of alle basis-systemen er helemaal netjes instaan, pas dan wil ik doorgaan met meer gebouwen en meer beesten

-   BUG: Sometimes animals forget to move their leg when jumping?!

-   ISSUE: What to do when selecting bunnies both inside/outside?

-   Create quick button to turn trees on/off, OR always maak animals \"shine through the trees"

-   Moet ik nog een limiet zetten op mutaties in DNA (ze zouden nu heel extreem kunnen worden).

*EIND OPTIMALIZATIE:*

-   Maak de clean() functies volledig af

-   Pas loops aan naar uitgebreide (maar snellere) variant

-   Voeg local variables toe/sla berekeningen op waar nodig

    -   Bijv, **love.graphics** of de **REGIONS** variable kan ik in principe localizeren

*Worlds We Used To Own*

Je begint als één persoon in een vreemde wereld, op één stukje grond. Je doel is uiteindelijk om vrede te stichten door de hele wereld; hoe je dat dan ook voor elkaar wilt krijgen.

*Klinkt niet erg origineel, wat is er bijzonder aan dit spel?*

-   Elk gebied kan maar één gebouw of "ding" bevatten, maar één functie hebben

-   Het speelt erg snel en dynamisch; er lopen constant beesten door de wereld.

-   Er zijn vele verschillende diersoorten die strijden.

-   Je dynastie opbouwen is belangrijk. Je moet de huidige populatie in leven zien te houden, en gelukkig houden. Keuzes die je aan het begin maakt, kunnen later grote impact hebben op je cultuur en hoe alles werkt.

-   Onderhandelen is veel belangrijker. Je kunt met andere naties een verbond sluiten, op wat voor manier dan ook.

-   De vecht-units zijn erg bijzonder, omdat ze gebruik maken van de specifieke kracht van het dier.

Wat kun je doen?

-   Gebouwen bouwen; in een gebied dat van jou is mag jij iets bouwen

-   Leger kweken; bepaalde gebouwen produceren bepaalde units

-   Andere speciale dingen maken?

-   Je poppetjes verplaatsen

-   Andere gebieden aanvallen

SOORT VAN SPELIDEE:

-   Dieren eten automatisch in het gebied waar ze in staan, mits er eten is.

-   Dieren krijgen een beetje water uit wat ze eten, maar je kunt ze ook zelf naar waterplekken sturen.

-   Wanneer dieren gezond genoeg zijn, en volwassen, en een veilige plek hebben (zoals, een konijnenhol), kunnen een mannetje en vrouwtje samen voortplanten.

    -   Afhankelijk van de diersoort, is er een bepaalde kans dat het lukt, draagtijd, en hoeveelheid baby's bij bevalling.

    -   Baby's zijn langzamer, minder sterk, hebben minder leven. Het duurt even voordat ze volwassen worden of kunnen vechten.

    -   De baby's kopiëren altijd een deel van de eigenschappen van de vader, en een deel van de moeder. Er is een hele, hele kleine kans op foutjes in het DNA. Je kunt dit dus gebruiken om alleen de beesten te krijgen die je wil, of het kan juist zorgen dat er iets belangrijks uitsterft.

-   Wanneer jij met een poppetje in een gebied staat, kun je er iets bouwen

    -   Je kunt alleen iets bouwen als het gebied onbeheerd is, in jouw beheer, of in het beheer van een bondgenoot.

    -   Je kunt hoogstens één ding bouwen in een gebied.

    -   Een gebied is pas van jou als er een ding van jou op staat.

    -   Dingen bouwen kost tijd en materiaal/mankracht.

    -   Elke diersoort kan twee dingen bouwen: eigen huisjes, en één speciaal gebouw

-   Door iets voor een andere diersoort te doen (waar zij om vragen) kun je een bondgenootschap sluiten. Dit heeft enkele voordelen:

    -   Je kunt ongehinderd door hun gebieden lopen.

    -   Je kunt hun gebouwen bouwen.

    -   Ze komen je helpen in geval van nood.

-   Dieren kunnen materialen oppakken, meeslepen, en ergens anders droppen. Tenzij het een speciale eigenschap is, is het niet mogelijk om een soort "reserve-voorraad" op te bouwen.

BUNNY:

-   Goede Eigenschappen: Speed, vision, and hearing

-   Slechte Eigenschappen: klein, zwak, kan weinig bouwen of doen om zichzelf te verdedigen

-   Vechtacties: bijten, stompen, krabben

-   Verdedigingsacties: vluchten in hol of boom

-   Gebouwen: hol, groeiweide, bosjes om te verstoppen, lage uitkijktoren/uitkijkplek

-   Bevalt snel en krijgt dan erg veel baby's. De ontlasting zorgt er meteen voor dat gras en planten beter/sneller groeien. De kracht van konijnen ligt dan ook in hun hoeveelheid en zelfvoorziening.

-   Sommige konijnen kunnen in (kleine) bomen klimmen

*TO DO List*

***HOU HET SIMPEL EN MOOI***

***HET IS MEER SCHATTIG EN CONSTRUCTIEF, DAN VECHTEN EN AFBREKEN***

*Het voelt alsof het spel nu meer een simulatie is dan een spel. De speler moet meer invloed hebben, meer interessante keuzes kunnen maken.*

HET OVERLEEF-SYSTEEM:

**HERBIVOREN:** Door de wereld heen groeien planten. Aan het begin van het spel worden bepaalde plantensoorten op bepaalde plekken neergepleurd.

> **PLANTEN ETEN:** Herbivoren eten deze planten. Ze schedulen een event om te eten, en als die plaatsvindt, zoeken ze een plant in de region, lopen daar naartoe, en gaan eten.
>
> Wanneer het konijn geen plant in de region vindt, zoekt deze in een buur-regio en gaat eventueel daarheen. Wanneer niks wordt gevonden, wordt weer een event gescheduled om te gaan eten. Als ze bijna sterven van de honger, krijgt de speler een signaal.
>
> Je kunt ook konijnen zelf naar eten toesturen door ze te selecteren, en vervolgens op een plant te klikken.
>
> **PLANTEN KRIJGEN:** Elk beest heeft om de zoveel tijd een "ontlasting"-event gescheduled. Wanneer deze plaatsvindt wordt op hun huidige plek een zaadje geplant. Ook kan een dier zaadjes meenemen en "droppen" wanneer hij/zij wil.
>
> Elk zaadje schedult een event om groter te groeien. (Grote planten doen dit meerdere keren). Wanneer het een plant is geworden kun je er van eten, en herhaalt de cyclus zich. Planten sterven nooit uit zichzelf.

**CARNIVOREN:** Door de wereld heen lopen beesten. Sommige beesten zijn van spelers, anderen zijn "van niemand" en lopen gewoon random door de wereld.

> **BEESTEN ETEN:** Carnivoren schedulen een event om te eten, en als die plaatsvindt zoeken ze hun maaltijd in hun eigen region, en eventueel een buurt-region.
>
> Anderzijds, wanneer deze niet gevonden wordt, kun je ze zelf naar eten toesturen. Je selecteert de carnivoor, je selecteert het beest dat je wilt hebben, en tada.
>
> Afhankelijk van de skill van de carnivoor en zijn prooi, is er een bepaalde kans dat het lukt. Wanneer het lukt, kun je er voor kiezen om de prooi terug te slepen naar je eigen gebied, zodat de rest van je roedel ook mee kan eten.
>
> **BEESTEN KRIJGEN:** Tja, een deel wordt door een random timer verzorgd, en een deel door de computerspelers.

HET SPECIALITEITEN-SYSTEEM:

Elk beest heeft een specialiteit. Deze hangt af van het "DNA" van de vader en moeder, en random kans/mutatie natuurlijk. De specialiteit geeft aan waar dit beest veruit het beste in is, maar betekent niet per sé dat het niks anders kan.

De specialiteiten zijn:

-   **Builder:** Bouwt gebouwen sneller, kan speciale gebouwen bouwen.

-   **Worker:** Kan (speciale) zaadjes planten, zorgt dat planten sneller groeien.

-   **Fighter:** Heeft meerdere eigenschappen die hem sterk maken in verdedigen/vechten. (Bijvoorbeeld, snel rennen, tegenstanders van verder aan zien komen, harder trappen, etc.)

-   **Survivor**: Kan (zware) spullen slepen, is extra sterk en gezond, kan veel verdragen. (Misschien kan hij zelfs baby's op z'n rug dragen?)

DNA: Bepaalt niet zo zeer met welk getalletje je dier geboren wordt, maar hoe *snel het iets aanleert/groeit*. Verder is er ook wat DNA wat samenhangt met gedrag en uiterlijk, maar dat is minder belangrijk. Elk dier heeft voor elke eigenschap twee waardes ("allelen"), die elk "AAN" of "UIT" kunnen zijn.

-   Vachtkleur

-   Grootte

-   Snelheid

-   Kracht

-   Zicht

-   Vecht-techniek

-   Inzicht/kennis

-   Gezondheid

-   "Heeft weinig eten nodig"

-   "Krijgt veel baby's"

-   "Kan goed omgaan met planten"

Elke keer als een dier wordt geboren worden de allelen van de ouders willekeurig gemixt en gematcht. Heel, heel soms ontstaat er een mutatie. Een mutatie betekent dat één of meerdere eigenschappen een onmogelijke waarde aannemen, wat een konijn ofwel ENORM goed ergens in maakt, ofwel GEHANDICAPT.

IDEE: Planten hebben bepaalde eigenschappen. Sommige planten hebben meer voedselinhoud, sommige meer water, en andere zijn meer geneeskrachtig of maken je beesten sterker.

IDEE 2: Elke plant ziet er anders uit en wordt dan ook "dynamisch" gegenereerd. Dus, bijv, door een bepaald aantal bessen aan een plant te hangen kun je zien hoeveel er nog aan zit, en hoeveel voeding je er dus uit kan halen.

ITEMS/SLEEPMECHANISME:

Dingen moeten gesleept kunnen worden voor het bouwen van "gebouwen" en voor het vervoeren van voedsel enzo. De dingen die gesleept kunnen worden zijn natuurlijk alle items.

Uit bepaalde dingen ontstaan items. De mogelijke items zijn:

-   Bomen zorgen voor hout en zaadjes

-   Stenen zorgen voor, nouja, stenen

-   Bosjes zorgen voor takjes

-   Planten zorgen voor zaadjes/bladeren/kruiden/bessen?

Maak onderscheid tussen dingen "oppakken/droppen" en dingen "verbruiken". HOE?

Bijvoorbeeld, een konijn is ziek, dan kan een ander geneeskrachtige kruiden/bladeren/zaadjes halen, en bij die ander droppen. Het zieke konijn verbruikt deze door ze op te eten.

Stappenplan:

-   Wanneer items ontstaan, worden ze op volgorde ge-insert in de regio.

-   Wanneer een geselecteerd konijn right-clicks op een item, wordt deze er op af gestuurd, en pakt het item eenmaal daar.

-   Dieren dragen items in hun mond? Of zweeft het gewoon boven hun hoofd?

-   Een item dat wordt gepakt, wordt uit de regio gehaald en aan het konijn-object vastgemaakt.

-   Wanneer een konijn is geselecteerd, en een item heeft, en je right-clickt op een ander konijn -- dan loopt ie daar naar toe en geeft het item aan die ander.

-   Wanneer een konijn is geselecteerd, en een item heeft, krijgt ie twee extra knopjes in de GUI: "use item", en "drop item"

-   Wanneer een konijn is geselecteerd, en een item heeft, en je right-clickt op het konijn zelf, dan ... (dit kan een soort "sneltoets" zijn naar een veelgebruikte functie)

Dit roept een vraag op: bij het doorgeven van items, evenals bij het aanvallen van dieren, kan die ander natuurlijk bewegen/weglopen. Hoe zorg ik er voor dat eens in de zoveel tijd opnieuw wordt gecheckt waar het dier is, zonder dat het veel computerkracht vereist?

> OPLOSSING: Wanneer een dier het doelwit is van een ander, wordt dat opgeslagen in dat dier. Wanneer deze beweegt geeft ie meteen een signaaltje naar iedereen die hem volgt.

Tweede vraag: als ik zo'n heel sleepsysteem bouw, moet het wel echt van belang zijn.

> OPLOSSING 1: Je kunt dingen die je sleept ook aan andere dieren geven, daarmee win je hun vertrouwen/vriendschap/hulp
>
> OPLOSSING 2: Voor het bouwen van gebouwen zijn materialen nodig, en je kunt meer bouwen dan alleen je eigen type huis.
>
> OPLOSSING 3: Vechters dragen constant takken voor het vechten, bouwers dragen constant zaadjes om te planten.

ITEMS \<=> GEBOUWEN

**HUIS**:

Vaak alleen maar tijd en mankracht nodig, eventueel hout en steen. (Hangt af van diersoort)

**VOEDSEL:**

> Voor prooidieren is dit een "plantage" waar konijnen bezig zijn zoveel mogelijk planten te onderhouden. (Vereist zaadjes en water.)
>
> Voor roofdieren zijn dit "valkuilen" waar prooidieren in kunnen lopen, maar die dus wel steeds moeten worden gereset/leeggehaald (?) (Vereist hout.)

**VERDEDIGING:**

> Alle dieren hebben een "trainingscentrum" waar ze over tijd sterker worden, en waar wapens worden gemaakt. (Zowel centrum als wapens vereisen hout en steen.)

**SPECIAAL:** Iedere diersoort heeft een ander speciaal gebouw.

> Konijn:
>
> Vos:

Elk gebouw heeft een bepaalde hoeveelheid materiaal nodig. Dit materiaal moet geleverd worden voordat het gebouw af kan zijn, door een dier het materiaal op te laten pakken, en vervolgens right-click op het te-maken-gebouw te doen. Echter, bouwen kost ook tijd \-\-- hoe voeg ik dat samen?!

OPLOSSING 1: Het bouwen van iets is verdeeld in "tijdstapjes" en (een mindere hoeveelheid) "materiaalstapjes". Na een aantal tijdstapjes wordt een extra materiaal verwacht. Als die al is afgeleverd, gaan we gewoon door -- zo niet moet iemand die gaan halen en terugbrengen. Dit gaat door tot alle tijdstapjes zijn volbracht (en, indirect dus, al het materiaal geleverd)

DIERENSTERFTE: Wanneer een animal sterft, vervang object door "skeleton"-object. Dit is de dode versie van een beest, en ligt plat op de grond en doet natuurlijk verder niks. De enige reden dat het blijft liggen is zodat prooidieren er van kunnen eten, én omdat het natuurlijk raar zou zijn als een dier ineens weg is.

VERDER

-   EVENTS: Slapen en drinken?

-   GUI CLASS:

    -   Detail: GUI dingessen niet helemaal centered

-   PERFORMANCE:

    -   Zonder fog, helemaal uitgezoomd gaat de FPS al hard omlaag (terwijl we nog helemaal niet zoveel dieren hebben). Ik heb het voor nu opgelost om gewoon natuur niet te laten zien als we zijn uitgezoomd, maar misschien is er nog een alternatief (zoals natuur laten zien door middel van blokjes/cirkels).

-   ENVIRONMENT:

    -   freeLocation systeem kan misschien wat algemener, aangezien er vast nog andere gebouwen komen die meer ruimte innemen

    -   Als een konijnenhol wordt verwoest waar nog konijnen inzitten sterven deze? Of gaan ze er netjes eerst uit?

    -   Sand/Desert terrain: Yellow

    -   => Option 1: transition between grass and mountain

    -   => Option 2: desert is an alternative to grass

-   BEWEGING:

    -   Fog-verspreiding weer helemaal laten werken, en af laten hangen van sight van het dier

    -   Animaties kunnen waarschijnlijk beter en efficiënter, maar ze werken voor nu prima.

-   DETAILS:

    -   Schaduw van konijnenhol loopt niet helemaal lekker

IDEA: What about weather conditions? And much more terrain types with more influence?

Elke region heeft zijn eigen weerstoestand. Eens in de zoveel tijd wordt deze met een bepaalde kans doorgegeven aan neighbours. De weerstoestand is alleen te zien wanneer ingezoomd, en moet helemaal in de draw() function zitten (om performance goed te houden). De mogelijke weertoestanden zijn: regen, sneeuw, storm (?)

Dit kan goed samen in combinatie met seizoenen. In de herfst/winter is het erg lastig om nog veel eten te vinden/laten groeien, dus moet er vooral eten worden gespaard en *niet* worden voortgeplant. In de lente/zomer echter groeit en bloeit alles, en is het verstandig om voort te planten en het rijk uit te breiden.
