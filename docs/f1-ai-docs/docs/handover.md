---
sidebar_position: 2
---

# Handover Guide

Use this page as the primary takeover checklist for the F1 AI Commentary project.

## 1. Validate Current Scope

- Confirm the current delivery state through [Sprint Minutes](/sprints).
- Review open and completed work in [Kanban](/docs/agile/kanban).
- Confirm active API contracts in [API Reference](/api).

## 2. Review Product Artefacts

- Start with [Wireframes](/docs/assets/wireframe) for UI intent and flow.
- Review [Poster](/docs/assets/poster) for presentation context.
- Check [Team Assets](/docs/assets/team-assets) for shared visual resources.

## 3. Understand Documentation Structure

- [Intro](/docs/intro): high-level purpose and navigation.
- [Asset Gallery](/docs/assets/overview): consolidated visual artefacts.
- [Kanban](/docs/agile/kanban): delivery evidence and sprint traceability.
- [API Reference](/api): endpoint behavior and schema.

## 4. Ongoing Ownership Expectations

- Keep handover pages aligned with new sprint outcomes.
- Add or update assets in stable static paths before linking in docs.
- Prefer newest-first ordering for galleries and updates where relevant.
- Record operational assumptions and unresolved risks explicitly in docs.

## 5. Definition of an Up-to-Date Handover Site

- Navigation points to the latest sprint evidence, API schema, and design artefacts.
- Asset pages reflect current repository content and priorities.
- Incoming contributors can locate implementation context within a few clicks.

## 6. Runbook: Local Development

### Backend (FastAPI)

From repository root:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python run.py
```

Expected result:

- Uvicorn starts and serves the API on port `8000`.
- API docs are available at `/docs` on the backend host.

Required environment:

- Ensure `OPENAI_API_KEY` is present in `backend/fast_app/.env`.

### Frontend (Flutter)

From repository root:

```bash
cd frontend
flutter doctor
flutter pub get
flutter analyze
flutter run
```

For web preview:

```bash
flutter run -d chrome
```

## 7. Runbook: Testing and Quality Gates

### Backend Tests

From repository root:

```bash
cd backend
source venv/bin/activate
pytest .
```

### Backend Lint

```bash
cd backend
source venv/bin/activate
pylint fast_app --fail-under=7.0
```

### Frontend Tests and Lint

```bash
cd frontend
flutter analyze
flutter test --coverage --dart-define=FLUTTER_TEST=true
```

CI reference:

- Workflow: `.github/workflows/ci.yml`

## 8. Runbook: Documentation Site

From repository root:

```bash
cd docs/f1-ai-docs
npm install
npm start
```

Build validation:

```bash
npm run build
```

## 9. Runbook: Deployment Checks

### Backend CD

- Workflow: `.github/workflows/cd-aws.yml`
- Trigger: push to `main` or `dev`
- Deployment target:
	- `main` branch maps backend container to host port `8000`
	- `dev` branch maps backend container to host port `8001`

### Frontend CD

- Workflow: `.github/workflows/deploy-frontend.yml`
- Trigger: push to `main` or `dev`
- Build mode: Flutter web release build
- Branch-based API configuration:
	- `main` uses production API/WebSocket URLs
	- `dev` uses development API/WebSocket URLs

### Post-Deploy Smoke Check

Verify all of the following:

- Frontend site loads in browser without console errors.
- Backend health route responds at `/`.
- API schema is reachable from the docs `/api` page.
- One end-to-end playback flow can be started successfully.

## 10. Incident Recovery Quick Steps

Use this order when diagnosing environment issues:

1. Validate branch and latest workflow run status in GitHub Actions.
2. Re-run backend locally with `python run.py` and confirm startup logs.
3. Re-run frontend with `flutter run -d chrome` to isolate UI issues.
4. Rebuild docs with `npm run build` to confirm documentation integrity.
5. Check API contract changes in `/api` and confirm consumers still align.
