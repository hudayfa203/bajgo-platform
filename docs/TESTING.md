# BajGo — testing the demo APKs

Two installable Android apps, built by GitHub Actions:

| App | Artifact | File inside |
|---|---|---|
| Customer | `BajGo-Customer-Demo` | `BajGo-Customer-Demo.apk` |
| Driver | `BajGo-Driver-Demo` | `BajGo-Driver-Demo.apk` |

Both are **demo builds** (`--dart-define=DEMO=true`). They run entirely on the
phone against a simulated backend: no server, no SMS, no real money. Every
screen carries a yellow "demo data" strip so a demo build can never be mistaken
for the live app.

## 1 · Download

1. Open <https://github.com/hudayfa203/bajgo-platform/actions/workflows/android-apks.yml>
2. Click the most recent green run.
3. Scroll to **Artifacts** and download `BajGo-Customer-Demo` and
   `BajGo-Driver-Demo`. Each is a zip containing the `.apk` and a
   `SHA256SUMS.txt`.
4. Unzip on the phone (Samsung's **My Files** opens zips directly) or unzip on a
   computer and copy the `.apk` across.

GitHub keeps the artifacts for 30 days. To rebuild, open the workflow and press
**Run workflow**.

### Checking the download

Each run prints the size and SHA-256 of every APK in its summary annotations, and
`SHA256SUMS.txt` ships inside the zip. On a computer:

```bash
sha256sum BajGo-Driver-Demo.apk   # compare with SHA256SUMS.txt
```

## 2 · Install on a Samsung phone

The APKs are signed with the Android debug key, so Android treats them as apps
from an unknown source.

1. Tap the `.apk` in **My Files**.
2. Android asks to allow installs from this app (usually My Files or Chrome) —
   **Settings → Install unknown apps → allow**.
3. Install. If Play Protect warns about an unknown developer, choose
   **Install anyway**.
4. Both apps can be installed side by side: the package names differ
   (`com.bajgo.customer`, `com.bajgo.driver`).

Minimum Android 6.0 (API 23). Built against API 36.

### Permissions to grant

| App | Permission | Why |
|---|---|---|
| Both | Location (while using the app) | centres the map, simulates movement |
| Driver | Photos / media | document and vehicle photo uploads |
| Both | Notifications | trip status changes |

The driver app tracks location only in the foreground in this build; continuous
background tracking needs a foreground service, which is **not implemented yet**.

## 3 · Signing in

There is no SMS in a demo build.

- Enter any valid Somali mobile number: `90 000 0000`, or with the country code
  `+252 90 000 0000`. Leading `0`, `252` and `00252` are all accepted.
- **The OTP is always `123456`.** The code is also shown on screen in the demo
  build so nobody has to remember it.
- Customer app: after the code, enter a full name once.
- Driver app: after the code, the five-step registration runs — name, Bajaaj
  (plate, make, colour, year), documents, emergency contact, payout method.
  Photos are optional; the documents screen accepts any image from the gallery.
  The demo approves the account immediately so the whole workflow is testable.
  On a real backend the account stays *pending* until an administrator approves it.

Sign-in survives restarting the app; **Log out** on the account screen clears it.

## 4 · End-to-end script — ride

Run the two apps on one phone (switch between them) or on two phones.

**Customer**

1. Home shows the Garowe map with simulated Bajaajs nearby.
2. Tap **Ride**. Pick a pickup and a drop-off from the list of Garowe landmarks,
   or drop a pin on the map.
3. Check the quote. The fare is **$0.50 per km, $1.00 minimum**, rounded up to
   the nearest 10 cents, so 3 km is $1.50 and 10 km is $5.00.
4. **Confirm**. The screen shows *searching*, then a driver accepts within a few
   seconds and the marker starts moving.
5. Watch the statuses: accepted → arriving → arrived → in progress → completed.
6. Pay cash, then rate the driver. The receipt shows the fare breakdown.

**Driver**

1. Toggle **Go online**. An offer arrives within ~8 seconds, then every 25–50
   seconds while you stay free and online.
2. The offer card counts down from 20 seconds and shows the pickup, the
   drop-off, the distance and the earnings after commission. Accept or decline.
3. Work the trip: **Navigate** → **Arrived** → **Passenger on board** →
   **Complete ride** → **Collect cash** → rate the customer.
4. **Earnings** shows gross, commission, net, the cash collected, a seven-day
   bar chart and the wallet ledger. **$0.10 commission is deducted per
   completed booking** in the demo, so after four trips the ledger shows
   `-$0.40` of commission.
5. Request a payout (minimum $5.00) and watch it appear in the payout history
   as *requested*.

## 5 · End-to-end script — delivery

**Customer**: tap **Delivery**, set pickup and drop-off, choose a package size
and category, fill in the recipient's name and phone, then confirm. The flow is
the same but the statuses differ: collected → in transit → at drop-off →
recipient verified → delivered.

**Driver**: accept a delivery offer, then **Package collected** → **Start
delivery** → **Arrived at destination** → **Enter recipient code**. The code is
the 4 digits shown on the customer's tracking screen (in a demo build; over SMS
in production). A wrong code is rejected. **Can't deliver** records a failure
reason and shows the return-to-sender instruction.

## 6 · What the demo does not do

Stated plainly, because a demo that overstates itself is worse than no demo:

- **The two apps do not talk to each other.** Each simulates its own
  counterpart, so a trip you book in the customer app does not appear in the
  driver app. Cross-app dispatch, the admin dashboard and live tracking need the
  backend running (`backend/`, in progress).
- **No real payments.** EVC Plus, ZAAD and Sahal are listed and selectable, but
  nothing is charged and no provider is integrated — those integrations are
  awaiting merchant credentials.
- **No real SMS.** OTP delivery needs an SMS gateway account.
- **No push notifications.** In-app notifications only.
- **Routes are straight-line approximations** (haversine × 1.30) rather than
  road routing, and map tiles come from OpenStreetMap.
- **Debug-signed.** Fine for testing, not for the Play Store.
- Place names in the demo are **placeholders** for well-known Garowe landmarks;
  coordinates are approximate and have not been surveyed.

## 7 · Building a live APK

Once the backend is deployed and reachable, open the workflow, press **Run
workflow** and put the backend's base URL in `api_base_url`. The job then also
builds `BajGo-customer-Live.apk` and `BajGo-driver-Live.apk` with `DEMO=false`,
which use the real API, real OTP and the real dispatcher. Demo mode is compiled
out of those builds: `Env.useMock` is false whenever `APP_ENV=production`.

## 8 · Reporting a problem

Note the app, the screen, what you tapped and what happened, and whether the
yellow demo strip was visible. The build number is on the account screen
(**App version**), and it matches the Actions run number.
