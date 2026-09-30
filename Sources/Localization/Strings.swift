import Foundation

/// Every piece of text in the app and widget, in Portuguese (PT-PT) and English.
///
/// The language is a choice made inside the app, not something inherited from
/// the system locale, so the strings live in code and switch instantly.
/// Split into small tables to keep type-checking quick.
enum Strings {

    typealias Pair = (pt: String, en: String)

    static let all: [String: Pair] = {
        var table: [String: Pair] = [:]
        let groups: [[String: Pair]] = [
            common, splash, onboarding, home, needs, stages, forms, moods, actions,
            refusals, toasts, events, overlays, games, shop, album, stats,
            achievements, settings, howTo, notifications, widget, a11y,
        ]
        for group in groups {
            table.merge(group) { _, new in new }
        }
        return table
    }()

    static func t(_ key: String, _ language: AppLanguage) -> String {
        guard let pair = all[key] else { return key }
        return language == .pt ? pair.pt : pair.en
    }

    static let common: [String: Pair] = [
        "common.ok": ("OK", "OK"),
        "common.close": ("Fechar", "Close"),
        "common.cancel": ("Cancelar", "Cancel"),
        "common.continue": ("Continuar", "Continue"),
        "common.save": ("Guardar", "Save"),
        "common.playAgain": ("Jogar outra vez", "Play again"),
        "time.days": ("%dd %dh", "%dd %dh"),
        "time.hours": ("%dh %dm", "%dh %dm"),
        "time.minutes": ("%d min", "%d min"),
    ]

    static let splash: [String: Pair] = [
        "splash.tagline": ("O teu animal de estimação virtual", "Your virtual pet"),
        "about.developedBy": ("Developed by David Arsénio Martins", "Developed by David Arsénio Martins"),
        "about.body": ("O clássico animal de estimação virtual, reimaginado para iPhone e iPad. Cuida dele, vê-o crescer e descobre as oito formas adultas.",
                       "The classic virtual pet, reimagined for iPhone and iPad. Look after it, watch it grow and discover all eight adult forms."),
        "about.version": ("Versão %@", "Version %@"),
        "about.website": ("Website", "Website"),
        "about.github": ("GitHub", "GitHub"),
    ]

    static let onboarding: [String: Pair] = [
        "onboarding.welcome": ("Bem-vindo ao iTamagotchi", "Welcome to iTamagotchi"),
        "onboarding.chooseLanguage": ("Escolhe o idioma", "Choose your language"),
        "onboarding.eggTitle": ("Um ovo misterioso", "A mysterious egg"),
        "onboarding.newEggTitle": ("Chegou um novo ovo", "A new egg has arrived"),
        "onboarding.tapEgg": ("Toca no ovo para o ajudar a nascer", "Tap the egg to help it hatch"),
        "onboarding.hatched": ("Nasceu!", "It hatched!"),
        "onboarding.nameTitle": ("Como se vai chamar?", "What will you call it?"),
        "onboarding.namePlaceholder": ("Nome", "Name"),
        "onboarding.begin": ("Começar a cuidar", "Start caring"),
        "onboarding.randomName": ("Sugerir nome", "Suggest a name"),
    ]

    static let home: [String: Pair] = [
        "room.living": ("Sala", "Living room"),
        "room.bedroom": ("Quarto", "Bedroom"),
        "room.garden": ("Jardim", "Garden"),
        "home.shop": ("Loja", "Shop"),
        "home.album": ("Álbum e Diário", "Album & Journal"),
        "home.stats": ("Estatísticas", "Stats"),
        "home.settings": ("Definições", "Settings"),
        "home.demo": ("DEMO", "DEMO"),
        "status.title": ("Cartão de estado", "Status card"),
        "status.rename": ("Mudar o nome", "Rename"),
        "status.age": ("Idade", "Age"),
        "status.weight": ("Peso", "Weight"),
        "status.stage": ("Fase", "Stage"),
        "status.form": ("Forma", "Form"),
        "status.mistakes": ("Erros de cuidado", "Care mistakes"),
        "status.weightValue": ("%d g", "%d g"),
        "status.unknownForm": ("Ainda por descobrir", "Not revealed yet"),
    ]

    static let needs: [String: Pair] = [
        "need.hunger": ("Fome", "Hunger"),
        "need.happiness": ("Felicidade", "Happiness"),
        "need.energy": ("Energia", "Energy"),
        "need.hygiene": ("Higiene", "Hygiene"),
        "need.health": ("Saúde", "Health"),
        "need.discipline": ("Disciplina", "Discipline"),
    ]

    static let stages: [String: Pair] = [
        "stage.egg": ("Ovo", "Egg"),
        "stage.baby": ("Bebé", "Baby"),
        "stage.child": ("Criança", "Child"),
        "stage.teen": ("Adolescente", "Teen"),
        "stage.adult": ("Adulto", "Adult"),
        "stage.senior": ("Sénior", "Senior"),
    ]

    static let forms: [String: Pair] = [
        "form.astro": ("Astro", "Astro"),
        "form.astro.trait": ("Raro. Sonhador e brilhante, criado com todo o cuidado.",
                             "Rare. Dreamy and brilliant, raised with the greatest care."),
        "form.luna": ("Luna", "Luna"),
        "form.luna.trait": ("Raro. Calmo e sereno, sempre dormiu às escuras.",
                            "Rare. Calm and serene, always slept in the dark."),
        "form.pudding": ("Pudim", "Pudding"),
        "form.pudding.trait": ("Guloso e fofo. Adora snacks, talvez demais.",
                               "Sweet and squishy. Loves snacks, maybe too much."),
        "form.sunny": ("Solinho", "Sunny"),
        "form.sunny.trait": ("Alegre e cheio de energia, espalha bom humor.",
                             "Cheerful and full of energy, spreads good vibes."),
        "form.nimbus": ("Nimbo", "Nimbus"),
        "form.nimbus.trait": ("Educado e descontraído, anda nas nuvens.",
                              "Polite and laid-back, head in the clouds."),
        "form.ember": ("Brasa", "Ember"),
        "form.ember.trait": ("Impulsivo e brincalhão, com um feitio quente.",
                             "Impulsive and playful, with a fiery temper."),
        "form.pebble": ("Seixo", "Pebble"),
        "form.pebble.trait": ("Resistente e simples, contenta-se com pouco.",
                              "Tough and simple, happy with little."),
        "form.grumble": ("Resmungão", "Grumble"),
        "form.grumble.trait": ("Rabugento por fora, carente por dentro.",
                               "Grumpy outside, needy inside."),
    ]

    static let moods: [String: Pair] = [
        "mood.happy": ("Feliz", "Happy"),
        "mood.content": ("Bem-disposto", "Content"),
        "mood.sad": ("Triste", "Sad"),
        "mood.hungry": ("Com fome", "Hungry"),
        "mood.sleepy": ("Com sono", "Sleepy"),
        "mood.sleeping": ("A dormir", "Asleep"),
        "mood.sick": ("Doente", "Sick"),
        "mood.angry": ("Birrento", "Throwing a tantrum"),
        "mood.dirty": ("Sujo", "Dirty"),
    ]

    static let actions: [String: Pair] = [
        "action.feed": ("Comer", "Feed"),
        "action.meal": ("Refeição", "Meal"),
        "action.snack": ("Snack", "Snack"),
        "action.play": ("Brincar", "Play"),
        "action.clean": ("Limpar", "Clean"),
        "action.bath": ("Banho", "Bath"),
        "action.medicine": ("Remédio", "Medicine"),
        "action.lightsOff": ("Apagar luz", "Lights off"),
        "action.lightsOn": ("Acender luz", "Lights on"),
        "action.scold": ("Repreender", "Scold"),
        "action.feedHint": ("Arrasta a comida até ao animal ou toca nela",
                            "Drag the food to your pet, or tap it"),
    ]

    static let refusals: [String: Pair] = [
        "refusal.asleep": ("Shh… está a dormir.", "Shh… it's sleeping."),
        "refusal.full": ("Está cheio, não quer mais.", "It's full and doesn't want more."),
        "refusal.nothingToClean": ("Está tudo limpo.", "Everything is already clean."),
        "refusal.notSick": ("Não está doente e não gostou do remédio.", "It isn't sick and didn't like the medicine."),
        "refusal.unfair": ("Não estava a fazer birra. Ficou triste.", "It wasn't misbehaving. Now it's sad."),
        "refusal.tooTired": ("Está cansado demais para brincar.", "It's too tired to play."),
        "refusal.notHatched": ("Ainda não nasceu.", "It hasn't hatched yet."),
    ]

    static let toasts: [String: Pair] = [
        "toast.overfed": ("Snacks a mais! Está com dor de barriga.", "Too many snacks! It has a tummy ache."),
        "toast.disciplined": ("Parou a birra. Disciplina a subir!", "Tantrum over. Discipline up!"),
        "toast.cured": ("Já se sente melhor!", "It's feeling better!"),
        "toast.achievement": ("Conquista: %@", "Achievement: %@"),
        "toast.bought": ("Comprado!", "Purchased!"),
        "toast.notEnough": ("Moedas insuficientes", "Not enough coins"),
        "toast.tantrum": ("%@ está a fazer birra!", "%@ is throwing a tantrum!"),
        "toast.lightsMistake": ("Dormiu mal com a luz acesa.", "It slept badly with the lights on."),
    ]
}
