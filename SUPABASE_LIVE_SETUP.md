# SilverHands — Supabase Live Prototype Setup

This build uses Supabase for authentication, profile persistence, opportunities, interested/match decisions and collaboration partner data.

## 1. Run the database migrations

In Supabase Dashboard → SQL Editor, run these files in order:

1. `supabase/migrations/001_silverhands.sql`
2. `supabase/migrations/002_live_prototype.sql`

The second migration adds the profile AI fields and the collaboration partner directory used by the live prototype.

For Family Guide, run `003_family_guide.sql` and `004_family_guide_code_rpc.sql`. If you get `Could not find the table 'public.guide_links' in the schema cache`, run `005_family_guide_install.sql` once instead; it is idempotent and installs the complete Family Guide database setup.

## 2. Configure the backend

Create `backend/.env` from `backend/.env.example` and provide:

- `GEMINI_API_KEY`
- `ELEVENLABS_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Never put the Supabase service-role key in Flutter.

## 3. Start FastAPI

```powershell
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

## 4. Run Flutter

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

Live Supabase mode is now the default. To intentionally run the offline demo mode:

```powershell
flutter run -d chrome --dart-define=SILVERHANDS_DEMO_MODE=true
```

## Live data flow

`voice → ElevenLabs → skills → profiles → AI recommendations → matches → collaboration`

### Tables used

- `profiles` — user livelihood profile and AI-generated summary
- `seller_profiles` — user's live seller/capacity record
- `opportunities` — real opportunity catalog
- `matches` — interested/skip decisions
- `collaboration_partners` — verified demo partner directory stored in Supabase
- `knowledge_documents` — RAG knowledge base


## 5. Family Guide setup

Run `supabase/migrations/003_family_guide.sql` after the first two migrations, then run `supabase/migrations/004_family_guide_code_rpc.sql` to enable secure member-side code generation.

The family-guide flow is:

1. The SilverHands member opens **My Profile → Trusted family guide**.
2. The member generates a temporary 6-digit code (valid for 30 minutes).
3. The family member creates/signs into a SilverHands account and chooses **Family guide**.
4. The guide enters the code, their name and relationship.
5. The guide gets a separate dashboard showing only the connected member's profile, published opportunities, interested opportunities and help activity.
6. The member remains the owner of all major details.

### Guide permissions

**Guide can:**
- View the connected member's profile.
- View skills, experience, verification status and published opportunities.
- Review interested opportunities.
- Record non-sensitive help activity.
- Help the member understand sharing/content workflows.

**Guide cannot:**
- Edit the member's name, skills, experience or identity verification.
- Change Aadhaar/identity information.
- Change financial ownership or payout information.
- Change the member's password.
- Grant themselves access or bypass the connection code.
- Continue access after the member revokes the connection.

The restrictions are enforced by Supabase RLS; the Flutter UI is not the security boundary.

## Family Guide Assistance (006)

After the existing Family Guide migrations, run `supabase/migrations/006_family_guide_assistance.sql` in Supabase SQL Editor.

This adds the member-approval workflow for guide assistance:
- Guides can request help/approval for opportunities, content, messages, safety and orders.
- The linked member can approve or reject pending requests from `Profile -> Trusted Family Guide`.
- Guides can read their request history but cannot approve their own requests.
- Requests are bound to the authenticated guide/member relationship with RLS and database functions.

The guide dashboard also provides:
- Protected member profile viewing (read-only)
- Opportunity review and approval requests
- Interested-match review
- Content assistant with WhatsApp sharing
- Customer reply drafting with member approval
- Safety keyword checks for common OTP/payment/credential scams
- Guide activity and request history

Run Flutter after the migration:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```
