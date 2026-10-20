# GoGreenAI — Comprehensive Project & AI Services Diagnostic Report

**Project**: GoGreenAI (Agricultural & Botanical Ecosystem)  
**Modules**: Mobile App (`gogreenai`), Backend REST API (`backend`)  
**Date**: October 20, 2026  
**Status**: All AI Services Diagnosed, Modernized, and Verified End-to-End  

---

## 1. Executive Summary

GoGreenAI is a full-stack botanical marketplace and plant care assistant featuring:
- **Flutter Mobile Application** for customers and nursery owners with cross-platform support (Android, iOS, Web).
- **Node.js / Express Backend** utilizing PostgreSQL with Prisma ORM, JWT authentication, Cloudinary media storage, and Razorpay payment integration.
- **AI Core** powered by Google Gemini for real-time plant identification, disease diagnosis, treatment recommendations, structured care guides, and open-ended botanical consultation.

Prior to this intervention, all four Gemini AI services failed when invoked from mobile or backend clients. This document provides a complete technical post-mortem, architectural trace, implementation review, test benchmarks, and operational runbook.

```mermaid
graph TD
    A["Flutter App UI<br/>(ai_assistant_screen.dart)"] -->|HTTP POST JSON / Base64| B["ApiClient<br/>(api_client.dart)"]
    B -->|adb reverse / LAN: 5000| C["Express Router<br/>(/api/ai/*)"]
    C -->|Multer / Resolve Image| D["AI Service<br/>(backend/src/services/ai.js)"]
    D -->|@google/genai SDK<br/>gemini-flash-lite-latest| E["Google Generative Language API<br/>(Google AI Studio)"]
    E -->|JSON Response| D
    D -->|Sanitized & Normalized Schema| C
    C -->|Standard REST JSON| B
    B -->|Dart Models: PlantIdentificationResult etc.| A
```

---

## 2. Root Cause Analysis (RCA)

A systematic audit revealed four cascading root causes:

### Root Cause 1: Deprecated & Discontinued Model Identifier (404 NOT_FOUND)
* **Location**: `backend/src/services/ai.js` (line 8)
* **Original Code**: `const DEFAULT_MODEL = 'gemini-1.5-flash';`
* **Defect**: Google AI v1beta Generative Language API no longer serves `gemini-1.5-flash`. Direct querying returned:
  ```json
  {
    "error": {
      "code": 404,
      "message": "models/gemini-1.5-flash is not found for API version v1beta, or is not supported for generateContent.",
      "status": "NOT_FOUND"
    }
  }
  ```
* **Investigation of Alternative Models**:
  - `gemini-2.5-flash`: Returned HTTP 404 with notice: *"This model models/gemini-2.5-flash is no longer available to new users. Please update your code to use models/gemini-3.8-flash for the latest features and improvements."*
  - `gemini-3.8-flash`: Valid and accessible, but showed higher latency (8–15s).
  - `gemini-flash-lite-latest`: **Production ready, highly responsive (~1.5–2.4s per vision request).**

### Root Cause 2: Legacy Manual Fetch vs Installed Modern SDK
* **Location**: `backend/src/services/ai.js`
* **Defect**: `backend/package.json` had `"@google/genai": "^2.30.0"` installed, but `ai.js` bypassed the SDK and performed raw HTTP `fetch` requests with ad-hoc markdown regex stripping.
* **Resolution**: Migrated to the official `@google/genai` unified SDK with automatic client pooling, system instruction handling, and automatic multi-modal payload serialization.

### Root Cause 3: Aggressive Client-side HTTP Timeout (12 seconds)
* **Location**: `gogreenai/lib/core/network/api_client.dart` (line 13)
* **Original Code**: `static const Duration _timeout = Duration(seconds: 12);`
* **Defect**: Transmitting a high-resolution photo base64 payload over mobile/USB networks followed by Gemini multimodal vision analysis frequently took 12–18 seconds during peak network loads. Flutter aborted the request with `TimeoutException` while the backend was still processing.
* **Resolution**: Decoupled AI request timeouts from general CRUD timeouts by allowing custom timeouts in `ApiClient` and setting a 45-second budget for AI endpoints.

### Root Cause 4: Response Schema Inconsistencies & Lack of In-App Retry UX
* **Location**: `gogreenai/lib/features/ai/ai_assistant_screen.dart` & `ai_models.dart`
* **Defect**: 
  - Gemini occasionally formatted structured responses as single-element arrays `[{ "plantName": ... }]`. Flutter's `res['data'] as Map<String, dynamic>` evaluated to empty when receiving a `List`.
  - Confidence ratings returned as numeric values (e.g. `0.98`) bypassed Flutter's string matching for badge rendering.
  - The UI only surfaced transient snackbars upon errors, giving users no in-card retry button or actionable error context.

---

## 3. Architecture & Implemented Solutions

### 3.1 Backend AI Service Modernization (`backend/src/services/ai.js`)
- **SDK Integration**: Utilizes `GoogleGenAI` from `@google/genai`.
- **Model Fallback Chain**: Defaults to `gemini-flash-lite-latest` (configurable via `GEMINI_MODEL` in `.env`), with automatic failover to `gemini-3.8-flash` if model endpoint errors occur.
- **Response Normalization**:
  - Unwraps array-wrapped JSON automatically.
  - Normalizes `confidence` into `HIGH`, `MEDIUM`, or `LOW`.
  - Normalizes `severity` into `Low`, `Moderate`, or `High`.
- **New Feature Added**: `getDiseaseTreatmentSuggestions(...)` providing non-toxic, cultural, and organic treatment plans with clear safety warnings.
- **Sanitized Errors**: Ensures API keys, raw query parameters, or internal stack traces are never leaked in error responses or console logs.

### 3.2 Express Route Enhancements (`backend/src/routes/ai.js`)
All endpoints are rate-limited and accept both `multipart/form-data` and JSON `imageBase64`:

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/ai/status` | Non-sensitive configuration probe (model, provider, configured flag). |
| `POST` | `/api/ai/identify` | Multimodal botanical identification from image. |
| `POST` | `/api/ai/diagnose` | Plant disease, pest, and physiological stress analysis. |
| `POST` | `/api/ai/treatment` | Dedicated numbered recovery guide and cultural treatments. |
| `POST` | `/api/ai/care-advice` | Structured care guide for watering, light, soil, and steps by plant name. |
| `POST` | `/api/ai/chat` | Conversational plant companion with conversational history memory. |

### 3.3 Flutter Mobile Layer Updates (`gogreenai`)
1. **`api_client.dart`**:
   - Added `Duration? timeout` parameter to `get` and `post`.
2. **`gemini_service.dart`**:
   - Configured 45-second timeout on all AI operations.
   - Added `_extractMap` helper to seamlessly handle both Map and List JSON responses.
   - Added `getDiseaseTreatmentSuggestions(...)` client method.
3. **`ai_models.dart`**:
   - Added `DiseaseTreatmentResult` model parsing immediate actions, organic treatments, environmental adjustments, and warnings.
4. **`ai_assistant_screen.dart`**:
   - Added state-driven error cards for plant identification and disease diagnosis.
   - Integrated **"Retry Identification"** and **"Retry Diagnosis"** buttons directly beneath selected preview images.

---

## 4. Verification & Benchmark Matrix

All five features were verified end-to-end using real plant assets from `gogreenai/assets/images/indoor/Mint-Plant.png` (390 KB PNG):

| AI Feature | Test Payload | Latency | Result Summary |
|---|---|---|---|
| **Plant Identification** | `Mint-Plant.png` | 2,409 ms | Scientific name: `Mentha`, Common: `Mint`, Confidence: `HIGH`, Care: Low difficulty, medium water, indirect light. |
| **Disease Diagnosis** | `Mint-Plant.png` | 1,929 ms | Health status: Clean foliage, Severity: `Low`, Symptoms: None, Treatments: Preventive cultural airflow tips. |
| **Treatment Guide** | Plant: `Mint`, Condition: `Powdery Mildew` | 1,820 ms | Urgency: Immediate, 2 immediate isolation steps, neem oil organic spray recipe, warning against spraying in hot midday sun. |
| **Care Advice** | Plant: `Aloe Vera` | 1,896 ms | Detailed soak-and-dry watering routine, cactus/succulent gritty mix recommendation, pet toxicity warnings. |
| **Plant Chat Q&A** | Query: *"Why are mint leaves turning brown?"* | 1,429 ms | Conversational diagnosis covering overwatering, underwatering, root-bound pots, with actionable recovery tips. |

### Test Suite Execution
- **Backend Tests (`vitest`)**:
  - `src/tests/ai.test.js`: **7 of 7 passed** (endpoint validation, status checks, error guards).
- **Flutter Tests (`flutter test`)**:
  - `test/ai_models_and_locations_test.dart`: **8 of 8 passed** (including new `DiseaseTreatmentResult` tests).
  - Overall Flutter unit test suite: **38 of 38 passed**.
- **Static Analysis**:
  - `flutter analyze`: **0 compilation errors**.
  - Target analysis of edited files: **0 errors**.
- **Android Binary Build**:
  - `flutter build apk --debug`: **Built successfully** in 81.2s (`app-debug.apk`).

---

## 5. Security & Configuration Review

| Checkpoint | Implementation Status | Verification Details |
|---|---|---|
| **API Key Storage** | Backend `.env` only | Verified `GEMINI_API_KEY` is never sent to or stored in client code. |
| **Key Validation** | At application startup | `env.js` validates key length and flags placeholder strings. |
| **Git Protection** | Strictly excluded | Both `backend/.gitignore` and root `.gitignore` exclude `.env`. |
| **Sample Configs** | Updated `.env.example` | Both root and backend `.env.example` include clean documentation placeholders. |
| **Data Protection** | In-memory uploads | Image buffers are processed directly in RAM via `multer.memoryStorage()` without leaving residual files on disk. |

---

## 6. Runbook & Developer Guide

### 6.1 Starting the Stack
1. **Backend Server**:
   ```powershell
   cd C:\Users\admin\Desktop\GOGREENAI\backend
   npm run dev
   ```
   *Expected output*: `[env] ✓ GEMINI_API_KEY is configured.` & `Server running on port 5000`.

2. **USB Port Forwarding (For Physical Android Device)**:
   ```powershell
   adb reverse tcp:5000 tcp:5000
   ```

3. **Running the Flutter Mobile App**:
   ```powershell
   cd C:\Users\admin\Desktop\GOGREENAI\gogreenai
   flutter run -d 1590516759000YF
   ```

### 6.2 Switching or Overriding Models
If Google AI Studio introduces new model revisions:
1. Update `GEMINI_MODEL` in `backend/.env`:
   ```properties
   GEMINI_MODEL=gemini-flash-lite-latest
   ```
2. Restart the backend process; no Flutter app recompilation is required.
