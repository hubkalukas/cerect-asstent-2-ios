# cerect asstent 2 (iOS / Apple)

## ⬇️ [Stáhnout cerect_asstent_2_ios.ipa (GitHub Release)](https://github.com/hubkalukas/cerect-asstent-2-ios/releases/latest/download/cerect_asstent_2_ios.ipa)

Nativní **SwiftUI** aplikace pro iPhone a iPad (iOS 16+) — iOS verze asistenta **cerect asstent 2** pro rychlou analýzu kvízů a Kahoot obrazovek pomocí Google Gemini API.

## Hlavní funkce
- **1-klik skenování přes iOS Zkratky (`AppIntents`):** Obsahuje akci **`Analyzovat obrazovku`**, kterou lze navázat na **Klepnutí na zadní stranu iPhonu (Back Tap)**, **plovoucí bod AssistiveTouch v rohu** nebo **Tlačítko Akce (Action Button)**.
- **Stealth horní banner + vibrační kód:** Zobrazí barevný tvar (`🔴 ▲`, `🔵 ◆`, `🟡 ●`, `🟢 ■`) a umí zavibrovat podle barvy (1× červená, 2× modrá, 3× žlutá, 4× zelená).
- **Bez umělých limitů v aplikaci:** Primární model **`gemini-3.5-flash-lite`** (~0,7 s) → automatické zálohy `gemini-3.1-flash-lite` → `gemini-3.6-flash` → `gemini-3.8-flash` (timeout 7 s).
- **Chráněný API klíč:** V aplikaci ani v čitelném textu kódu není API klíč zobrazitelný.
- **Automatický cloudový build `.ipa`:** GitHub Actions na macOS automaticky sestavuje a publikuje `cerect_asstent_2_ios.ipa` do Releases.

## Jak nainstalovat na iPhone
1. Stáhni `cerect_asstent_2_ios.ipa` z odkazu nahoře.
2. Nainstaluj do iPhonu přes **AltStore**, **SideStore**, **Sideloadly** (z Windows/Macu) nebo **TrollStore**.
3. V aplikaci **Zkratky (Shortcuts)** vytvoř zkratku:
   - *Pořídit snímek obrazovky*
   - *Analyzovat obrazovku (cerect asstent 2)*
4. V *Nastavení → Zpřístupnění → Dotyk → Klepnutí na zadní stranu* (nebo *AssistiveTouch*) vyber tuto zkratku.
