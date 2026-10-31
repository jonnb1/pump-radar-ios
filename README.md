# Pump Radar

Pump Radar is an iPhone watchlist for unusual crypto readings. The board ranks coins, names the signal families that fired, and explains each row in one plain-English sentence.

It does not buy or sell, does not connect a wallet, and does not promise profit. Every screen carries a not-financial-advice line.

The app targets **iOS 17 or later**. Demo mode is on the first time you open it, so the board, coin pages, and events feed work with **bundled sample data** before any server exists.

[![iOS CI](https://github.com/jonnb1/pump-radar-ios/actions/workflows/ios.yml/badge.svg)](https://github.com/jonnb1/pump-radar-ios/actions/workflows/ios.yml)

## Screens

| Screen | What it shows |
| --- | --- |
| **Board** | Ranked coins: score, the families that fired, and one sentence about why. Swipe a row and tap **Watch** to keep it on this iPhone. Search, and switch between All and Watching. |
| **Coin** | The same sentence, an honest scorecard (how many families fired and which stayed quiet), the readings that fired, related events, and a simple price path when the feed included prices. **Watch on this iPhone** does not trade. |
| **Events** | Listings, ETF flow days, and X buzz spikes, newest first. Filters sit at the top. |
| **Settings** | Demo mode, the API base URL, Simple or Pro, optional on-device alerts, what each family means, and the disclaimer. |

**Simple** keeps a row to the score, the family names, and the sentence. **Pro** adds the price, each family's score, the quiet families, and whether the coin passed the server's data-quality filter. Passing that filter is not a recommendation to trade. The toggle is in the board's top corner and in Settings.

Sample screens are labeled **Sample data — not live market readings**.

## You do not need a Mac

Builds run on a GitHub-hosted Mac. This phone is enough:

1. Merge this project (or run the workflow on its branch).
2. Add four secrets, using Safari on the iPhone. Steps are below.
3. Run **iOS CI** from the Actions tab.
4. Install Apple's TestFlight app and open the build.

Until those secrets exist, **Build & Test** still compiles the app and runs the unit tests. The **TestFlight** job then ends green and says the upload was skipped.

## Put Pump Radar on your iPhone

You need a **paid Apple Developer Program** membership (the free Apple ID cannot use TestFlight), and the iPhone's App Store signed in to that same Apple ID.

The bundle id the cloud build uses is **`com.pumpradar.ios`**. Type it exactly. The app name in App Store Connect can be **Pump Radar**. The version uploaded from CI is **0.1.0**. The build number is the GitHub Actions run number.

Safari on an iPhone hides some of these buttons. Whenever a page looks empty or has no plus button, tap the **aA** icon in the address bar and choose **Request Desktop Website**.

### 1. Copy your Team ID

1. Open [developer.apple.com/account](https://developer.apple.com/account).
2. Sign in with the Apple Developer account.
3. Request the desktop website.
4. Open **Membership details**.
5. Copy **Team ID**. It is 10 letters and numbers.

That value is the GitHub secret `APPLE_TEAM_ID`.

### 2. Register the bundle id

1. Open [Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Request the desktop website.
3. Tap the **+** button.
4. Choose **App IDs**, then **App**, then Continue.
5. Description: `Pump Radar`.
6. Bundle ID: **Explicit**, then `com.pumpradar.ios`.
7. Leave the capability checkboxes off.
8. Tap **Register**.

### 3. Create the app record

Do this before the first upload. Apple rejects an upload that does not match an app.

1. Open [App Store Connect apps](https://appstoreconnect.apple.com/apps).
2. Request the desktop website.
3. Tap **+** and then **New App**.
4. Platforms: **iOS**. Name: `Pump Radar`. Primary language: English.
5. Bundle ID: `com.pumpradar.ios`. SKU: `pumpradar-ios`.
6. User access: Full Access. Tap **Create**.

You do not need screenshots, a price, or a review submission for this internal TestFlight build.

### 4. Create an App Store Connect API key

The cloud Mac signs the app with this key. You download the key file **once**. Apple will not show it again. If you lose it, revoke that key and make a new one.

1. Open [Users and Access](https://appstoreconnect.apple.com/access/users).
2. Request the desktop website.
3. Open **Integrations**. If you do not see Integrations, open **Keys**. It is the same page. Direct link that often works: [App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
4. Under **App Store Connect API**, choose **Team Keys** if both Team Keys and Individual Keys are shown.
5. Tap **Generate API Key** (or the **+**).
6. Name: `Pump Radar CI`.
7. Access: **Admin**. A lower role can fail when the Mac tries to create a certificate.
8. If you see **Access to Certificates, Identifiers, and Profiles**, turn it on. The archive step needs it.
9. Generate the key.
10. Copy two values from this screen before you leave it:
    - **Issuer ID**, the UUID at the top of the keys page. This is `APP_STORE_CONNECT_ISSUER_ID`.
    - **Key ID**, about 10 characters, in the keys table. This is `APP_STORE_CONNECT_KEY_ID`.
11. Tap **Download API Key** and save `AuthKey_XXXXXXXXXX.p8`. It lands in the Files app, usually in Downloads or iCloud Drive.

### 5. Copy the key file into text

The GitHub secret needs the **contents** of that `.p8` file, not the file name. On an iPhone, the Shortcuts app can read it.

**If you can get the text** (it is short and starts with `-----BEGIN PRIVATE KEY-----`):

1. Open **Shortcuts**. Tap **+**.
2. Add the **File** action and choose the downloaded `AuthKey_….p8`.
3. Add **Get Contents of File**. If it asks for a type, choose **Text**.
4. Add **Copy to Clipboard**.
5. Run the shortcut.

**If the clipboard looks empty**, encode it instead. The workflow accepts this form too:

1. **File** action, same `.p8`.
2. **Base64 Encode**.
3. **Copy to Clipboard**.

That clipboard value is `APP_STORE_CONNECT_KEY_P8`.

### 6. Save the four GitHub secrets

1. Open [the Actions secrets page](https://github.com/jonnb1/pump-radar-ios/settings/secrets/actions).
2. Request the desktop website if you do not see **New repository secret**.
3. Add one secret at a time. The name must match exactly. Paste the value with no extra quotes.

| Secret name | Where the value came from |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | Key ID on the API keys page |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID on that same page |
| `APP_STORE_CONNECT_KEY_P8` | The `.p8` text, or the base64 from Shortcuts |
| `APPLE_TEAM_ID` | Team ID from Membership details |

Leave `PRODUCT_BUNDLE_IDENTIFIER` unset. The build uses `com.pumpradar.ios`. Set that secret only if you registered a different id on purpose, and use the same id here, in Identifiers, and on the App Store Connect app.

### 7. Run the build

1. Open [iOS CI](https://github.com/jonnb1/pump-radar-ios/actions/workflows/ios.yml).
2. Tap **Run workflow**.
3. Choose branch **main** after this work is merged. Before that, choose the pull request branch.
4. Tap **Run workflow** again.
5. Wait until **Build & Test** is green, then until **TestFlight** finishes.

The first upload is the slow one. Apple creates a distribution certificate and a provisioning profile from the API key. Later runs reuse them.

If **TestFlight** is green but its summary says the upload was skipped, a secret name is missing or empty. Fix the secret and run the workflow again. You do not need a new API key unless the `.p8` itself was wrong.

### 8. Install with TestFlight

1. Install **TestFlight** from the App Store.
2. On the iPhone, stay signed in to the same Apple ID as the developer account.
3. In App Store Connect, open **Pump Radar → TestFlight**. Processing often takes 10 to 30 minutes after the GitHub job is green. The build shows as version **0.1.0**.
4. If a build asks about export compliance or encryption, answer **No**. The app already declares that it does not use non-exempt encryption, so this question may not appear.
5. Open **Internal Testing**. If there is no group, create one and add your user. Turn the new build on for that group.
6. Open the TestFlight app. Pump Radar should be listed under your team. Tap **Install**.

Internal testing does not need a Beta App Review. That review is only for testers outside your App Store Connect team, and it is not part of this proof of concept.

### If the upload fails

| What the log says | What to do |
| --- | --- |
| No suitable application records were found | Create the App Store Connect app in step 3, with bundle id `com.pumpradar.ios`, and run the workflow again. |
| No profiles or no signing certificate | Confirm the key role is Admin, the certificates checkbox was on, and the identifier from step 2 exists. Then run the workflow again. |
| The key could not be read | Replace `APP_STORE_CONNECT_KEY_P8` with the full file text, including the BEGIN and END lines, or with base64 of the whole file. |
| Missing Compliance, stuck processing | Open the build in TestFlight and answer **No** to encryption. |
| Invalid bundle or bundle id mismatch | The secret `PRODUCT_BUNDLE_IDENTIFIER`, the identifier, and the app record must be the same string. |

## Using the app

Demo mode is the default. The banner on the board and the events feed means the numbers are the sample files in the app, not a live market.

- Swipe a coin and tap **Watch**. The list is stored on the iPhone only.
- Tap the coin for the scorecard and the sentence behind the score.
- Switch **Simple** and **Pro** from the board's top button or from Settings.
- In Settings, **Notify on this iPhone** asks for notification permission and, after a refresh, posts a local alert when a watched coin reaches the score you set. There is no remote push. Alerts are off until you turn them on.

When a server is actually hosted:

1. Settings → paste the base URL, for example `https://api.example.com`. Do not add `/radar/board` yourself.
2. Turn **Demo mode** off.
3. Pull to refresh. If the phone cannot reach the server, the message offers **Use sample data**, which turns Demo mode back on.

The base URL may be `http://` for a private test host. Before an App Store release, point it at `https://` only.

## API the app calls

These are read-only GETs. The app sends no orders and no account token.

| Path | Used for |
| --- | --- |
| `{base}/radar/board` | Ranked rows |
| `{base}/radar/events` | Listings, ETF flows, buzz spikes |
| `{base}/radar/families` | Names and plain-English explanations |
| `{base}/radar/snapshots?symbol=PEPE` | Price path when a row did not include one |
| `{base}/signals/tradable` | Coins that passed a liquidity and data-quality filter |

`pump-radar-api` (including branch `cursor/tradable-momentum-signals-f92e`) and `pump-radar-backend` were not readable from this environment: GitHub returned 404. Nothing in those repositories was changed. The sample files in `PumpRadar/Resources/Demo` are the contract the app decodes. JSON may be snake_case or camelCase. A wrapper shaped like `{ "success": true, "data": { ... } }` is unwrapped. Dates are ISO-8601.

A board row looks like this:

```json
{
  "symbol": "PEPE",
  "name": "Pepe",
  "score": 81,
  "why": "One sentence a person can read without a terminal.",
  "families_fired": ["listings", "buzz", "momentum"],
  "signals": [
    {
      "family": "momentum",
      "name": "Price momentum",
      "score": 76,
      "fired": true,
      "summary": "What was unusual, in plain English.",
      "metrics": [{ "label": "24h move", "value": "+18%" }]
    }
  ],
  "sparkline": [1.0, 1.1, 1.2],
  "tradable": true
}
```

Family ids the sample board uses: `listings`, `etf_flows`, `buzz`, `momentum`, `sentiment`, `funding`, `order_book`, `divergence`.

Event `kind` values include `listing`, `etf_flow`, `buzz` (or `buzz_spike`), plus the other family names. Unknown kinds still show, labeled as a note.

Mark sample payloads with `"sample": true` and `"sample_label": "Sample data — not live market readings"` so the app keeps the banner up even outside Demo mode.

## Tests

`PumpRadarTests` covers:

- Decoding the bundled sample files, camelCase, `{ "data": ... }` envelopes, dictionary-shaped signals, and unknown event kinds
- Board ranking, search, the watchlist filter, composed sentences, the scorecard, the tradable-filter merge, and one-shot local alert decisions
- Demo mode loading the bundled files
- Coin detail filling a sparkline from snapshots
- Settings and watchlist persistence

GitHub Actions runs them on a macOS runner with an iPhone simulator. Signing is turned off for that job.

## Project layout

```
PumpRadar/
  App/                 entry point
  Models/              board, events, tolerant decoding
  ViewModels/          board, detail, events, scorecard
  Views/               Board, coin, events, settings
  Services/            live client, demo client, settings, watchlist
  Resources/Demo/      sample JSON, labeled as sample data
project.yml            XcodeGen project. The .xcodeproj is not committed.
.github/workflows/ios.yml
scripts/testflight.sh  archive and upload, used only by CI
```

Someone with a Mac can run `brew install xcodegen swiftlint`, then `xcodegen generate`, then open `PumpRadar.xcodeproj`. That is optional. The iPhone path above does not use it.
