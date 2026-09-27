import json
from pathlib import Path

from .models import Generation, Term
from .services.matcher import normalize

GENERATIONS = [
    {"key": "boomers", "name": "Boomers", "start_year": 1946, "end_year": 1964},
    {"key": "genx", "name": "Generazione X", "start_year": 1965, "end_year": 1980},
    {"key": "millennials", "name": "Millennials", "start_year": 1981, "end_year": 1996},
    {"key": "genz", "name": "Generazione Z", "start_year": 1997, "end_year": 2012},
    {"key": "genalpha", "name": "Generazione Alpha", "start_year": 2013, "end_year": 2025},
]

TERMS = [
    {
        "term": "boomer",
        "using": ["genz", "genalpha"],
        "definition": "Persona nata durante il baby boom (1946-1964); usato ironicamente per chi ha idee ritenute antiquate.",
        "example": "Ok boomer, smettila di lamentarti della tecnologia.",
    },
    {
        "term": "ok boomer",
        "using": ["genz", "genalpha"],
        "definition": "Espressione usata per chiudere una discussione con una persona più anziana ritenuta superata.",
        "example": "Mi ha detto 'ok boomer' e se n'è andato.",
    },
    {
        "term": "cringe",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Imbarazzante, che mette a disagio.",
        "example": "Quel video è troppo cringe.",
    },
    {
        "term": "rizz",
        "using": ["genz", "genalpha"],
        "definition": "Carisma, fascino, capacità di sedurre.",
        "example": "Ha un rizz incredibile.",
    },
    {
        "term": "godo",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Provo piacere, spesso per la sconfitta o sfortuna altrui.",
        "example": "Hai perso la partita? Godo.",
    },
    {
        "term": "based",
        "using": ["genz", "genalpha"],
        "definition": "Detto di persona o opinione autentica e senza compromessi.",
        "example": "Quella è un'opinione molto based.",
    },
    {
        "term": "chad",
        "using": ["genz", "genalpha"],
        "definition": "Ragazzo sicuro di sé e di successo, contrapposto al 'virgin'.",
        "example": "Si comporta come un chad.",
    },
    {
        "term": "skibidi",
        "using": ["genalpha"],
        "definition": "Termine nonsense diventato virale su TikTok, senza un significato preciso.",
        "example": "Skibidi toilet è il suo meme preferito.",
    },
    {
        "term": "sigma",
        "using": ["genz", "genalpha"],
        "definition": "Lupo solitario, indipendente, che non segue il branco.",
        "example": "Si definisce un sigma male.",
    },
    {
        "term": "mewing",
        "using": ["genz", "genalpha"],
        "definition": "Tecnica per definire la mascella tenendo la lingua premuta sul palato.",
        "example": "Fa mewing mentre studia.",
    },
    {
        "term": "aura",
        "using": ["genz", "genalpha"],
        "definition": "Energia e carisma; 'avere aura' significa avere una presenza forte.",
        "example": "Quel ragazzo ha un'aura pazzesca.",
    },
    {
        "term": "fanum tax",
        "using": ["genalpha"],
        "definition": "Scherzosamente, prendersi una parte del cibo di un amico.",
        "example": "Mi ha fatto la fanum tax sulle patatine.",
    },
    {
        "term": "gyat",
        "using": ["genz", "genalpha"],
        "definition": "Esclamazione di ammirazione, spesso per una persona attraente.",
        "example": "Gyat, che outfit!",
    },
    {
        "term": "delulu",
        "using": ["genz", "genalpha"],
        "definition": "Delirante, illuso (da 'delusional').",
        "example": "È delulu se pensa che lo richiamerà.",
    },
    {
        "term": "fomo",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Fear Of Missing Out: paura di perdersi qualcosa di interessante.",
        "example": "Non esco ma ho una fomo terribile.",
    },
    {
        "term": "vibe",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Atmosfera, sensazione, energia di una situazione.",
        "example": "Che bella vibe stasera.",
    },
    {
        "term": "pov",
        "using": ["genz", "genalpha"],
        "definition": "Point Of View: punto di vista, usato nei video per raccontare una scena.",
        "example": "Pov: sei arrivato in ritardo a scuola.",
    },
    {
        "term": "cap",
        "using": ["genz", "genalpha"],
        "definition": "Bugia; 'no cap' significa 'senza mentire, davvero'.",
        "example": "No cap, è andata proprio così.",
    },
    {
        "term": "drip",
        "using": ["genz", "genalpha"],
        "definition": "Stile, abbigliamento ricercato e di tendenza.",
        "example": "Guarda che drip quel paio di scarpe.",
    },
    {
        "term": "flexare",
        "using": ["genz", "genalpha"],
        "definition": "Ostentare, mettersi in mostra.",
        "example": "Smettila di flexare la tua macchina.",
    },
    {
        "term": "shippare",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Sperare che due persone formino una coppia (da 'relationship').",
        "example": "Shippo tantissimo quei due.",
    },
    {
        "term": "spoilerare",
        "using": ["millennials", "genz"],
        "definition": "Rivelare in anticipo la trama di un film o di una serie.",
        "example": "Non mi spoilerare il finale!",
    },
    {
        "term": "taggare",
        "using": ["millennials", "genz"],
        "definition": "Etichettare qualcuno in un post o in una foto sui social.",
        "example": "Mi ha taggato nella storia.",
    },
    {
        "term": "sbloccata",
        "using": ["genz", "genalpha"],
        "definition": "Raggiungere una svolta positiva; 'sbloccare una core memory' = rivivere un bel ricordo.",
        "example": "Quella canzone mi ha sbloccato una core memory.",
    },
    {
        "term": "periodt",
        "using": ["genz", "genalpha"],
        "definition": "Enfasi su ciò che si è appena detto: 'punto e basta'.",
        "example": "È il miglior film dell'anno, periodt.",
    },
    {
        "term": "in chill",
        "using": ["genz", "genalpha"],
        "definition": "Rilassarsi, stare tranquilli senza impegni.",
        "example": "Stasera sto in chill a casa.",
    },
    {
        "term": "gagà",
        "using": ["boomers", "genx"],
        "definition": "Dandy, uomo molto elegante e curato nell'aspetto.",
        "example": "Che gagà quel signore con il gilet.",
    },
    {
        "term": "togo",
        "using": ["boomers", "genx"],
        "definition": "Persona in gamba, valente.",
        "example": "Sei proprio un togo, complimenti.",
    },
    {
        "term": "gasato",
        "using": ["boomers", "genx"],
        "definition": "Esaltato, euforico, sopra le righe.",
        "example": "Era tutto gasato dopo la promozione.",
    },
    {
        "term": "gnegno",
        "using": ["boomers"],
        "definition": "Persona sciocca, ingenua, poco sveglia.",
        "example": "Non fare il gnegno, dai.",
    },
    {
        "term": "figata",
        "using": ["boomers", "genx", "millennials"],
        "definition": "Cosa bella, eccezionale, che piace molto.",
        "example": "Che figata quel concerto!",
    },
    {
        "term": "alzare il gomito",
        "using": ["boomers", "genx"],
        "definition": "Bere troppo alcol.",
        "example": "Ieri sera ha alzato il gomito più del solito.",
    },
    {
        "term": "fare il filo",
        "using": ["boomers"],
        "definition": "Corteggiare qualcuno con insistenza.",
        "example": "Le fa il filo da mesi.",
    },
    {
        "term": "battere la fiacca",
        "using": ["boomers", "genx"],
        "definition": "Lavorare o impegnarsi con poca energia.",
        "example": "Oggi batto la fiacca, sono stanco.",
    },
    {
        "term": "svaccato",
        "using": ["genx", "millennials"],
        "definition": "Sdraiato in modo scomposto, privo di energia.",
        "example": "Sono sul divano tutto svaccato.",
    },
    {
        "term": "scialla",
        "using": ["genx", "millennials"],
        "definition": "Stai tranquillo, non preoccuparti.",
        "example": "Scialla, andrà tutto bene.",
    },
    {
        "term": "sbobba",
        "using": ["boomers", "genx"],
        "definition": "Cibo molle e poco appetitoso.",
        "example": "In mensa c'era una sbobba immangiabile.",
    },
    {
        "term": "catorcio",
        "using": ["boomers", "genx"],
        "definition": "Vecchia automobile o oggetto in pessime condizioni.",
        "example": "Guida ancora quel catorcio del '90.",
    },
    {
        "term": "a sbafo",
        "using": ["boomers", "genx"],
        "definition": "Gratis, a spese di qualcun altro.",
        "example": "Mangia sempre a sbafo a casa mia.",
    },
    {
        "term": "bro",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Fratello; usato per rivolgersi a un amico, anche non parente.",
        "example": "Bella bro, come va?",
    },
    {
        "term": "sis",
        "using": ["genz", "genalpha"],
        "definition": "Sorella; versione femminile di 'bro', per rivolgersi a un'amica.",
        "example": "Sis, ci sentiamo dopo.",
    },
    {
        "term": "fra",
        "using": ["genz", "genalpha"],
        "definition": "Abbreviazione di 'fratello', usata per rivolgersi a un amico.",
        "example": "Fra, hai visto la partita?",
    },
    {
        "term": "zio",
        "using": ["genx", "millennials"],
        "definition": "Amico, compare; allocutivo amichevole informale.",
        "example": "Zio, che si dice?",
    },
    {
        "term": "gang",
        "using": ["genz", "genalpha"],
        "definition": "Il proprio gruppo di amici, la compagnia.",
        "example": "Stasera esco con la gang.",
    },
    {
        "term": "hype",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Eccitazione e attesa spasmodica per qualcosa.",
        "example": "C'è troppo hype per questo film.",
    },
    {
        "term": "hypato",
        "using": ["genz", "genalpha"],
        "definition": "Eccitato, carico, in fibrillazione.",
        "example": "Sono ipato per il concerto di domani.",
    },
    {
        "term": "triggerare",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Scatenare una reazione emotiva negativa in qualcuno.",
        "example": "Non mi triggerare con questi discorsi.",
    },
    {
        "term": "cringiare",
        "using": ["genz", "genalpha"],
        "definition": "Provare forte imbarazzo per qualcosa di cringe.",
        "example": "Mi fa cringiare quel video.",
    },
    {
        "term": "crashato",
        "using": ["genz", "genalpha"],
        "definition": "Mentalmente esaurito, in tilt, senza energie.",
        "example": "Oggi sono proprio crashato.",
    },
    {
        "term": "scam",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Truffa, fregatura.",
        "example": "Quel sito è uno scam.",
    },
    {
        "term": "ghostare",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Sparire smettendo di rispondere ai messaggi di qualcuno.",
        "example": "Mi ha ghostato dopo il primo appuntamento.",
    },
    {
        "term": "chillare",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Rilassarsi, stare tranquilli senza fare nulla.",
        "example": "Stasera chilliamo sul divano.",
    },
    {
        "term": "top",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Eccellente, il massimo.",
        "example": "Quella canzone è top.",
    },
    {
        "term": "flop",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Fallimento, insuccesso totale.",
        "example": "Il suo nuovo disco è un flop.",
    },
    {
        "term": "mood",
        "using": ["genz", "genalpha"],
        "definition": "Stato d'animo; 'essere un mood' significa rappresentare perfettamente un sentimento.",
        "example": "Questa canzone è proprio il mio mood.",
    },
    {
        "term": "slay",
        "using": ["genz", "genalpha"],
        "definition": "Eccellere, dare il meglio, essere fantastico.",
        "example": "Stasera mi vesto per slay.",
    },
    {
        "term": "bop",
        "using": ["genz", "genalpha"],
        "definition": "Canzone molto orecchiabile e ballabile.",
        "example": "Questa è una bop assurda.",
    },
    {
        "term": "baddie",
        "using": ["genz", "genalpha"],
        "definition": "Persona attraente e molto sicura di sé.",
        "example": "Lei è una vera baddie.",
    },
    {
        "term": "goblin mode",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Stato di pigrizia totale, senza curarsi delle apparenze.",
        "example": "Questo weekend sono in goblin mode.",
    },
    {
        "term": "trauma dump",
        "using": ["genz", "genalpha"],
        "definition": "Scaricare all'improvviso i propri traumi e problemi su un'altra persona.",
        "example": "Mi ha fatto un trauma dump senza preavviso.",
    },
    {
        "term": "lore",
        "using": ["genz", "genalpha"],
        "definition": "Storia di fondo, background di un personaggio o di una situazione.",
        "example": "Conosci il lore di questo personaggio?",
    },
    {
        "term": "canon",
        "using": ["genz", "genalpha"],
        "definition": "Coerente con la storia ufficiale; verità accertata.",
        "example": "Quella coppia è canon nella serie.",
    },
    {
        "term": "headcanon",
        "using": ["genz", "genalpha"],
        "definition": "Teoria personale non ufficiale su una storia o un personaggio.",
        "example": "Il mio headcanon è che si sposino.",
    },
    {
        "term": "main character",
        "using": ["genz", "genalpha"],
        "definition": "Protagonista; comportarsi come il centro della storia.",
        "example": "Oggi mi sento la main character.",
    },
    {
        "term": "villain era",
        "using": ["genz", "genalpha"],
        "definition": "Periodo in cui si adotta un atteggiamento distaccato e 'cattivo'.",
        "example": "Dopo la rottura è entrato nella sua villain era.",
    },
    {
        "term": "mid",
        "using": ["genz", "genalpha"],
        "definition": "Mediocre, nella media ma deludente.",
        "example": "Il film era mid, non lo riguarderei.",
    },
    {
        "term": "glow up",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Miglioramento radicale dell'aspetto o della condizione.",
        "example": "Ha avuto un glow up incredibile.",
    },
    {
        "term": "fit",
        "using": ["genz", "genalpha"],
        "definition": "Outfit, abbigliamento.",
        "example": "Che bel fit oggi.",
    },
    {
        "term": "fire",
        "using": ["genz", "genalpha"],
        "definition": "Fantastico, eccezionale.",
        "example": "Questa canzone è fire.",
    },
    {
        "term": "goat",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Greatest Of All Time: il migliore di sempre.",
        "example": "Messi è il goat del calcio.",
    },
    {
        "term": "ratio",
        "using": ["genz", "genalpha"],
        "definition": "Superare in popolarità un altro commento, ottenendo più risposte o like.",
        "example": "Gli ho fatto ratio su Twitter.",
    },
    {
        "term": "bot",
        "using": ["genz", "genalpha"],
        "definition": "Persona che agisce in modo meccanico e poco autentico.",
        "example": "Risponde come un bot.",
    },
    {
        "term": "npc",
        "using": ["genz", "genalpha"],
        "definition": "Persona senza personalità propria, che segue passivamente il gruppo.",
        "example": "Non fare il npc, pensa con la tua testa.",
    },
    {
        "term": "broccolo",
        "using": ["millennials", "genz"],
        "definition": "Persona imbranata, inetta, che combina pasticci.",
        "example": "Sei un broccolo a fare i compiti.",
    },
    {
        "term": "cazzeggiare",
        "using": ["genx", "millennials"],
        "definition": "Perdere tempo senza fare nulla di utile.",
        "example": "Ho passato il pomeriggio a cazzeggiare.",
    },
    {
        "term": "sbatti",
        "using": ["millennials", "genz", "genalpha"],
        "definition": "Scocciatura, fatica, noia.",
        "example": "Che sbatti andare in palestra oggi.",
    },
    {
        "term": "sbatta",
        "using": ["genz", "genalpha"],
        "definition": "Mancanza di voglia, noia, fastidio.",
        "example": "Ho una sbatta assurda oggi.",
    },
    {
        "term": "botta",
        "using": ["genx", "millennials"],
        "definition": "Colpo, scossone; 'che botta' indica uno shock o un'emozione forte.",
        "example": "Che botta la fine di quella serie.",
    },
    {
        "term": "pischello",
        "using": ["boomers", "genx"],
        "definition": "Ragazzo giovane e inesperto, pivello.",
        "example": "Quel pischello non sa cosa fa.",
    },
    {
        "term": "tamarro",
        "using": ["boomers", "genx", "millennials"],
        "definition": "Persona dal gusto volgare e vistoso.",
        "example": "Guida con la musica tamarra a tutto volume.",
    },
    {
        "term": "truzzo",
        "using": ["genx", "millennials"],
        "definition": "Persona che segue mode volgari e appariscenti.",
        "example": "È un po' truzzo con quei vestiti.",
    },
    {
        "term": "bimbominkia",
        "using": ["millennials", "genz"],
        "definition": "Ragazzino immaturo che si comporta da troll online.",
        "example": "Nei commenti ci sono solo bimbiminkia.",
    },
    {
        "term": "sfigato",
        "using": ["boomers", "genx", "millennials"],
        "definition": "Sfortunato, perdente, goffo.",
        "example": "Si sente sempre sfigato.",
    },
    {
        "term": "fare la gavetta",
        "using": ["boomers", "genx"],
        "definition": "Iniziare dai gradini più bassi di una carriera o attività.",
        "example": "Prima di dirigere ha fatto la gavetta per anni.",
    },
    {
        "term": "bischero",
        "using": ["boomers", "genx"],
        "definition": "Sciocco, ingenuo, poco sveglio (toscano).",
        "example": "Non fare il bischero, dai.",
    },
]


def seed(db) -> None:
    generation_by_key: dict[str, Generation] = {}
    for g in GENERATIONS:
        existing = db.query(Generation).filter(Generation.key == g["key"]).first()
        if existing is None:
            existing = Generation(**g)
            db.add(existing)
            db.flush()
        generation_by_key[g["key"]] = existing

    for t in TERMS:
        normalized = normalize(t["term"])
        existing = (
            db.query(Term)
            .filter(Term.language == "it", Term.normalized == normalized)
            .first()
        )
        generations = [generation_by_key[k] for k in t["using"]]
        if existing is None:
            db.add(
                Term(
                    language="it",
                    term=t["term"],
                    normalized=normalized,
                    definition=t["definition"],
                    example=t.get("example", ""),
                    source="manual",
                    generations=generations,
                )
            )
        else:
            if generations:
                existing.generations = generations
    db.commit()


def seed_from_dump(db) -> int:
    if db.query(Term).filter(Term.source != "manual").count() > 0:
        return 0

    path = Path(__file__).parent / "terms_dump.json"
    if not path.exists():
        return 0

    data = json.loads(path.read_text(encoding="utf-8"))
    generation_by_key = {g.key: g for g in db.query(Generation).all()}

    for item in data.get("terms", []):
        if item.get("source") == "manual":
            continue
        normalized = normalize(item["term"])
        gens = [
            generation_by_key[k]
            for k in item.get("generations", [])
            if k in generation_by_key
        ]
        db.add(
            Term(
                language=item["language"],
                term=item["term"],
                normalized=normalized,
                definition=item["definition"],
                example=item.get("example", ""),
                source=item.get("source", "web"),
                source_url=item.get("source_url", ""),
                generations=gens,
            )
        )
    db.commit()
    return db.query(Term).filter(Term.source != "manual").count()
