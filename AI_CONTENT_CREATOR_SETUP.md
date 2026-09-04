# SilverHands AI Content Creator

The Create tab is now profile-driven. It automatically reads the skills identified during voice onboarding and creates:

- an AI-generated poster preview
- a WhatsApp-specific customer message
- an Instagram caption
- a Facebook post

## Demo flow

1. Complete voice onboarding in Tamil/English/Hindi.
2. Confirm the detected skills.
3. Complete profile creation.
4. Open **Create** in the bottom navigation.
5. SilverHands automatically uses the saved skills, experience, language and location.
6. Gemini generates the marketing copy and poster text through `POST /api/content/generate`.
7. The poster is rendered in-app from the AI-generated headline/subheadline/CTA.
8. Tap **Share to WhatsApp**. On Chrome this opens WhatsApp Web with the WhatsApp-specific message prefilled. On mobile it opens the WhatsApp-compatible external link.
9. If WhatsApp cannot be opened, the message is copied automatically.

## Backend

The content response now contains:

- `whatsapp_status`
- `instagram_caption`
- `facebook_post`
- `poster_headline`
- `poster_subheadline`
- `poster_cta`

No new Supabase table is required for the demo. The content is generated from the already-persisted profile/skills and can be persisted later as a marketing-content history table.

## Run

```powershell
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

In another terminal:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

The new dependency is `url_launcher`, used only to open the WhatsApp share URL.
