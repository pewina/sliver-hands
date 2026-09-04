# SilverHands — Working Hackathon Prototype

## Run the demo

From the `silverhands` folder:

```powershell
flutter pub get
flutter run -d chrome
```

The project is configured for **Demo Mode by default**:

```text
SILVERHANDS_DEMO_MODE=true
```

This means the complete user journey works without Supabase, Firebase, Gemini, FastAPI, Google Maps keys, or WhatsApp configuration.

For a production-connected build, use:

```powershell
flutter run -d chrome --dart-define=SILVERHANDS_DEMO_MODE=false
```

## Judge demo flow

1. **Authentication** — tap `Continue with Demo Account`.
2. **Senior-first onboarding** — choose language, user type, voice-assisted skill identification, location, verification and trusted family guide.
3. **Discover** — swipe/press `Interested` or `Skip`.
4. **AI matching** — an interest action opens an animated `IT'S A MATCH` screen.
5. **Business details** — inspect order requirements and collaboration opportunity.
6. **Chat** — send a prefilled interest message and show the conversation flow.
7. **My Business** — show local trends, seasonal demand and AI business ideas.
8. **Create** — use the prefilled product, select the sample photo, generate AI content, switch WhatsApp/Instagram/Facebook, copy, share and publish.
9. **Matches** — open a match and enter chat.
10. **Profile** — edit details, change language, verify identity, add a trusted guide, view journey, toggle notifications and open the nearby-opportunities map.
11. **Journey** — show streak, badges, impact points and leaderboard.
12. **Repeat the demo** — Discover → `Reset demo journey`.

## Demo architecture

The prototype uses a small in-memory `DemoStore` and the existing repository interfaces. The UI is therefore interactive rather than a collection of static screenshots. When real services are configured, the repository paths can be switched back to Supabase/FastAPI.

### Demonstrated solution features

- Senior-friendly large-touch UI
- Email authentication/demo authentication
- Multilingual onboarding
- Voice-to-skill concept
- Safe identity-verification mock
- Trusted family guide
- AI-style opportunity recommendations
- Swipe-to-match livelihood discovery
- Local/seasonal demand
- Bulk-order collaboration
- Business chat
- AI-generated social content
- Product publishing flow
- Location-aware opportunity map
- Gamified streaks, badges and leaderboard
- Persistent-in-session demo state
