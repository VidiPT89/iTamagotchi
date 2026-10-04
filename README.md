# 🥚 iTamagotchi

> The classic virtual pet, natively reimagined for iOS and iPadOS with SwiftUI and SpriteKit.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/iTamagotchi/issues) [![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/iTamagotchi/issues)

## ✨ Features

- ✅ Full life cycle: egg, baby, child, teen, adult and senior, with a hatching animation and evolution cutscenes
- ✅ Branching evolutions: the adult form depends on how well the pet was cared for (8 possible forms)
- ✅ Six live needs: hunger, happiness, energy, hygiene, health and discipline
- ✅ Real-time simulation that keeps running while the app is closed, with an offline catch-up summary
- ✅ Care actions: meals and snacks, bath, cleaning, medicine, lights off for bedtime and discipline
- ✅ Four mini-games to play with the pet: Left or Right, Catch the Stars, Rhythm Tap and Sequence
- ✅ Fully procedural, animated pet: idle breathing, blinking, bouncing, moods, reactions and sleep states
- ✅ Thought bubble that shows what your pet wants right now
- ✅ Dynamic day and night cycle, weather ambience, and hats, wallpapers and room decorations bought with coins
- ✅ Local notifications when the pet is hungry, sick, sleepy or needs cleaning
- ✅ iCloud sync: the same pet on your iPhone and iPad
- ✅ Rename your pet any time from its status card
- ✅ Home Screen widget showing the pet and its needs at a glance, plus Lock Screen widgets for the most urgent need
- ✅ Fluid SpriteKit effects: particles, hearts, bubbles, confetti and evolution flashes
- ✅ Procedurally synthesized sound effects and music, with custom Core Haptics patterns
- ✅ Adaptive layout for iPhone and iPad, portrait and landscape
- ✅ Animated splash screen with developer credits, then straight into the main screen
- ✅ Runtime language switch: Português (PT-PT) and English, independent of the system locale (dates included)
- ✅ Dark mode, Light mode and System mode
- ✅ Colour identity taken from [ividi.dev](https://ividi.dev/): burnt orange, amber and near-black
- ✅ Life journal organised by pet, family album of past pets, lifetime stats and achievements
- ✅ Accessibility: VoiceOver labels, Dynamic Type and Reduce Motion support

## 🛠️ Tech Stack

| Category     | Technology                                  |
| ------------ | ------------------------------------------- |
| Language     | Swift 6                                     |
| UI           | SwiftUI                                     |
| Graphics     | SpriteKit                                   |
| Architecture | MVVM + UI-free simulation core              |
| Persistence  | Codable save in App Group; SwiftData journal and album |
| Sync         | iCloud key-value storage                    |
| Widgets      | WidgetKit                                   |
| Audio        | AVAudioEngine (synthesized, no audio files) |
| Haptics      | Core Haptics                                |
| Project      | XcodeGen                                    |
| Min. iOS     | 17.0                                        |

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 16+
- iOS 17+ Simulator or device (iPhone or iPad)

### Installation

```bash
git clone https://github.com/VidiPT89/iTamagotchi.git
cd iTamagotchi
open iTamagotchi.xcodeproj
```

Build and run (`⌘R`) on the simulator or a connected device.

> The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`. If you add or move Swift files, regenerate it with `xcodegen generate`.

## 📖 Usage

1. Tap the egg to start a new life and give your pet a name
2. Keep an eye on the needs panel: hunger, happiness, energy, hygiene, health and discipline
3. Feed, bathe, clean and play with your pet before any need runs out
4. Turn the lights off when it falls asleep and give it medicine when it gets sick
5. Good care leads to rarer evolutions, while neglect leads to grumpier ones

Language, appearance, notifications, sound, music and haptics are all adjustable in Settings.

## 🎮 Controls

| Input                 | Action                              |
| --------------------- | ----------------------------------- |
| Tap the pet           | Pet it and see its reaction         |
| Action bar buttons    | Feed, play, clean, bathe, heal, sleep |
| Drag food to the pet  | Feed by hand                        |
| Swipe on the room     | Switch between rooms                |
| Long press the pet    | Open its status card                |

## 🧪 Testing

```bash
xcodebuild -project iTamagotchi.xcodeproj -scheme iTamagotchi \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The suite covers simulation, life cycle, economy, save compatibility, cloud merge rules, localisation and app actions, including stale mini-game callbacks and offline farewells.

The current pet, inventory and lifetime stats sync through iCloud. The journal and family album remain local to each device. Concurrent play on two devices uses save replacement rather than merging individual actions. Physical-device checks are still needed for iCloud delivery, notifications, audio interruptions and haptics.

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

- 🌐 Website: [ividi.dev](https://ividi.dev/)
- 🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89/)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iTamagotchi/issues).

---

<p align="center">
  Developed by <a href="https://ividi.dev">David Arsénio Martins</a>
</p>

<p align="center">
  ⭐ If you like this project, give it a star!
</p>
