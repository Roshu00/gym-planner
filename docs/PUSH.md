# Push notifikacije

Šta stiže na telefon:

| Događaj | Kome | Primer |
|---|---|---|
| Trener odgovori na objavu | autoru objave | „Anja Blagojević: Pet kila više za dve nedelje!” |
| Objava dobije 1, 5, 10, 25, 50, 100… „Bravo” | autoru objave | „Bravo za Gluteus A · 12 ljudi iz tima ti je reklo Bravo.” |
| Trener napiše poruku za danas | svima u timu | „Anja Blagojević: Danas noge. Polako na čučnju.” |
| Neko iz tima obori rekord | treneru | „Mila J. · novi rekord · Hip thrust 60 kg” |

Kako radi: aplikacija šalje token telefona u `push_tokens` kad korisnik u timu dodirne „Javi mi”.
Trigeri u bazi upisuju obaveštenja u `push_queue`, a Edge Function `push` ih šalje preko Firebase-a
(APNs za iOS, FCM za Android). Bez Firebase podešavanja aplikacija radi normalno, samo bez pusha.

## Jednom, za projekat

1. **Firebase projekat** na console.firebase.google.com. Dodaj iOS aplikaciju sa bundle ID-jem
   aplikacije i preuzmi `GoogleService-Info.plist`.
2. **APNs ključ** u Apple Developer nalogu: Certificates, IDs & Profiles → Keys → novi ključ sa
   „Apple Push Notifications service”. Preuzmi `.p8` i zapiši Key ID i Team ID.
   U Firebase-u: Project settings → Cloud Messaging → Apple app configuration → otpremi `.p8`.
3. **Xcode**: otvori `ios/Runner.xcworkspace`, Runner → Signing & Capabilities → `+ Capability` →
   **Push Notifications**. Prevuci `GoogleService-Info.plist` u Runner (Copy if needed).
   Background Modes → Remote notifications je već uključen u `Info.plist`.
4. **Servisni nalog** za slanje: Firebase → Project settings → Service accounts →
   „Generate new private key” (JSON).
5. **Supabase**:
   ```bash
   supabase db push
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat servisni-nalog.json)" PUSH_WEBHOOK_SECRET=<nasumičan-niz>
   supabase functions deploy push --no-verify-jwt
   ```
   Pa u Dashboard → Database → Webhooks → novi webhook: tabela `push_queue`, događaj `INSERT`,
   tip „Supabase Edge Functions”, funkcija `push`, header `x-webhook-secret: <isti niz>`.

Ključeve i JSON servisnog naloga nikad ne stavljaj u repozitorijum.

## Provera

Push ne radi na iOS simulatoru za pravi APNs; probaj na telefonu. U Supabase-u
`select * from push_queue order by id desc` pokazuje šta je poslato (`sent_at`), a logovi funkcije
`push` koliko je stiglo i koji tokeni su obrisani kao nevažeći.
