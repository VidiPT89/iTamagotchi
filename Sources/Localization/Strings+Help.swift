import Foundation

extension Strings {

    static let howTo: [String: Pair] = [
        "howto.title": ("Como jogar", "How to play"),
        "howto.life.title": ("Ciclo de vida", "Life cycle"),
        "howto.life.body": ("Ovo, bebé, criança, adolescente, adulto e sénior. Cada fase dura mais do que a anterior e a simulação continua com a app fechada.",
                            "Egg, baby, child, teen, adult and senior. Each stage lasts longer than the last, and time keeps running while the app is closed."),
        "howto.needs.title": ("Necessidades", "Needs"),
        "howto.needs.body": ("Fome, felicidade, energia, higiene, saúde e disciplina descem com o tempo. Os anéis no topo mostram como estão.",
                             "Hunger, happiness, energy, hygiene, health and discipline drop over time. The rings at the top show how they're doing."),
        "howto.care.title": ("Cuidados", "Care"),
        "howto.care.body": ("Dá refeições e snacks (sem exagerar), limpa o cocó, dá banho, dá remédio quando estiver doente e apaga a luz quando adormecer.",
                            "Serve meals and snacks (in moderation), clean up poop, give baths, give medicine when it's sick and switch the lights off when it falls asleep."),
        "howto.discipline.title": ("Disciplina", "Discipline"),
        "howto.discipline.body": ("Às vezes faz birra sem precisar de nada. Educa-o nesse momento. Educar sem razão deixa-o triste.",
                                  "Sometimes it throws a tantrum without needing anything. Teach it right then. Doing it for no reason makes it sad."),
        "howto.evolution.title": ("Evolução", "Evolution"),
        "howto.evolution.body": ("A forma adulta depende de como foi criado: erros de cuidado, disciplina, felicidade e até o peso. Há oito formas, duas delas raras.",
                                 "The adult form depends on how it was raised: care mistakes, discipline, happiness and even weight. There are eight forms, two of them rare."),
        "howto.coins.title": ("Moedas e casa", "Coins and home"),
        "howto.coins.body": ("Ganha moedas nos mini-jogos e compra chapéus, decoração e papéis de parede. Desliza na sala para mudar de divisão.",
                             "Earn coins in the mini-games and buy hats, decor and wallpaper. Swipe the room to move between rooms."),
        "howto.gestures.title": ("Gestos", "Gestures"),
        "howto.gestures.body": ("Toca no animal para lhe fazer festas. Mantém o dedo para ver o cartão de estado. Ele segue o teu dedo com os olhos.",
                                "Tap your pet to cuddle it. Press and hold to see its status card. Its eyes follow your finger."),
    ]

    static let notifications: [String: Pair] = [
        "notif.hungry": ("%@ tem fome 🍙", "%@ is hungry 🍙"),
        "notif.hungry.body": ("A barriguinha está a dar horas. Que tal uma refeição?", "Its tummy is rumbling. Time for a meal?"),
        "notif.bored": ("%@ está aborrecido", "%@ is bored"),
        "notif.bored.body": ("Brinca um bocadinho com ele.", "Play with it for a little while."),
        "notif.dirty": ("Há cocó para limpar", "There's poop to clean"),
        "notif.dirty.body": ("%@ precisa que limpes a sala.", "%@ needs you to tidy up."),
        "notif.sleepy": ("%@ adormeceu", "%@ fell asleep"),
        "notif.sleepy.body": ("Apaga a luz para dormir bem.", "Turn the lights off so it sleeps well."),
        "notif.sick": ("%@ está doente", "%@ is sick"),
        "notif.sick.body": ("Dá-lhe um remédio para recuperar.", "Give it some medicine to recover."),
    ]

    static let widget: [String: Pair] = [
        "widget.name": ("O meu animal", "My pet"),
        "widget.description": ("O teu animal e as necessidades num relance.", "Your pet and its needs at a glance."),
        "widget.noPet": ("Abre a app para chocar o ovo", "Open the app to hatch the egg"),
        "widget.gone": ("Um novo ovo espera por ti", "A new egg is waiting"),
    ]

    static let a11y: [String: Pair] = [
        "a11y.pet": ("%@, %@, %@", "%@, %@, %@"),
        "a11y.need": ("%@: %d por cento", "%@: %d percent"),
        "a11y.openWebsite": ("Abrir ividi.dev", "Open ividi.dev"),
        "a11y.openGitHub": ("Abrir o GitHub de VidiPT89", "Open VidiPT89 on GitHub"),
        "a11y.petHint": ("Toca para fazer festas. Mantém para ver o estado.", "Tap to cuddle. Press and hold for status."),
        "a11y.poop": ("Cocó no chão", "Poop on the floor"),
        "a11y.skipSplash": ("Saltar apresentação", "Skip intro"),
    ]
}
