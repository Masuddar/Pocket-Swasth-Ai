# 🧬 Pocket Swasth AI

### *Autonomous Health Agent & Offline Native LLM Triage Companion*

Pocket Swasth AI is a state-of-the-art, privacy-first mobile healthcare assistant built with **Flutter**. Designed to bridge the gap between offline medical triage and advanced online clinical intelligence, the app features an autonomous decision engine, native on-device large language model (LLM) execution, real-time biosensor telemetry syncing, and digital twin support for medical practitioners.

---

## 🚀 Key Features

### 1. 🤖 Autonomous Clinical Triage Agent
Unlike simple conversational chatbots, Pocket Swasth AI implements a professional clinical decision engine:
*   **Multi-Signal Ingestion:** Combines subjective patient complaints, real-time telemetry (Heart Rate, SpO2, Stress levels), and uploaded digital health records.
*   **Risk Categorization:** Deterministically classifies patient clinical states into **LOW** (Safe), **MODERATE** (Clinical review recommended), or **EMERGENCY** (Immediate acute care).
*   **Automated Action Execution:** Triggers real-time local home monitoring, queues doctor appointments, or prepares emergency responder telemetry packages depending on the risk tier.

### 2. 🔀 Hybrid Intelligent AI Router
*   **Online Mode:** Connects seamlessly to **OpenRouter API** to run elite models (e.g., *Gemini 2.5 Flash*, *Llama 3.3 70B*, *Gemma 2 9B*) for deep, multi-turn diagnostic reasoning and validator workflows.
*   **Offline Mode:** Executes fully on-device on the CPU using **`llamadart`** (native bindings to `llama.cpp` for GGUF model runtimes) with zero cloud dependencies.
    *   **Layered Gibberish Shield:** Employs a multi-criteria grammar validator and connective word density filter to eliminate raw model hallucinations or repeat loops.
    *   **Hard Emergency Override:** Instantly triggers critical triage paths for flagged symptoms (e.g., crushing chest pain, slurred speech, loss of consciousness) without model delay.

### 3. ⌚ Biosensor & Wearables Sync
*   **Wearable Telemetry:** Syncs heart rate baseline and SpO2 trends from Apple Watch and Samsung Galaxy Watch.
*   **Software Signals:** Integrates advanced wellness markers:
    *   *Neuro-Gait Analysis* (locomotive stability tracking).
    *   *GPS Mobility Metrics* (circadian movement profiling).
    *   *rPPG Selfie Camera* (heart rate estimation via micro-facial blood flow change).
    *   *Voice Stress Analytics* (vocal tremor and cognitive loading markers).

### 4. 📇 Clinical Medical ID & Records Caching
*   **Local Caching:** Utilizes secure, local **Hive** key-value boxes to persist patient metrics, health histories, and AI logs.
*   **Comprehensive Health Profile:** Supports quick chip-management systems for:
    *   Chronic Conditions (e.g., Hypertension, Diabetes).
    *   Allergies & Severe Drug Intolerances.
    *   Vaccinations & Immunizations history.
    *   Emergency Contacts & Insurance validation.

### 5. 🏥 Digital Doctor Twin & Practitioner Console
*   **Doctor Twin:** Employs a specialized view allowing clinical specialists to monitor patient telemetry trends.
*   **Practitioner Console:** Synchronizes local patient vitals with doctor telemetry dashboards for supervised remote diagnostics.

### 6. 📷 Prescription OCR & Contraindication Validator
*   **Ingestion:** Scans medical prescriptions using advanced image and file pickers.
*   **Validation:** Parses text blocks to extract dosage instructions, validate medicines, and flag contraindications against documented patient allergies.

---

## 🛠️ Tech Stack & Dependencies

The project relies on a highly performant and secure stack:
*   **Framework:** Flutter (Dart SDK `^3.9.2`)
*   **Local Database:** `hive` & `hive_flutter` for ultra-fast, local data caching
*   **Offline LLM:** `llamadart` (native compilation bindings for `.gguf` inference)
*   **State Management:** `provider` (reactive change-notifiers)
*   **Formatting:** `flutter_markdown` for rendering beautiful, structured medical cards
*   **System Controls:** `image_picker` & `file_picker` for OCR scans, `url_launcher` for resources

---

## 📂 Project Architecture

```
lib/
├── core/
│   ├── constants/       # AppConstants, system prompts, emergency keywords
│   ├── theme/           # Premium Light/Dark design tokens
│   └── utils/           # Helper utilities
├── models/              # Diagnosis, MedicalKnowledgeUpdate, UserProfile models
├── providers/           # ChatProvider, HealthProvider, UserProvider, ModeProvider
├── routes/              # Dynamic routing controllers
├── screens/             # UI Views (Chat, Profile, SOS, Report, Doctor Twin, Console)
├── services/
│   ├── ai/              # AiRouter, OfflineLlmService, OpenRouterService
│   ├── medical/         # DiagnosisEngine, HealthRiskEngine, Prescription OCR/Validator
│   └── storage/         # Hive LocalDbService configurations
├── widgets/             # Reusable UI components (custom navigation, cards, typing bubble)
└── main.dart            # Application entry point & service initialization
```

---

## ⚙️ Setup & Installation

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
*   An Android Emulator, iOS Simulator, or physical testing device.

### 1. Clone the Repository
```bash
git clone https://github.com/Masuddar/Pocket-Swasth-Ai.git
cd Pocket-Swasth-Ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Place Offline LLM Models (Optional for Offline Mode)
To use local offline AI execution:
1. Create the model directory: `assets/models/` at the root of the project.
2. Download a lightweight quantized GGUF model, such as **SmolLM2-135M.Q4_K_M.gguf** or **Qwen2.5-0.5B-Instruct-Q4_K_M.gguf**.
3. Place the `.gguf` model file into the `assets/models/` folder.
*Note: Large model files are ignored by `.gitignore` to prevent repository bloat.*

### 4. Run the Application
```bash
flutter run
```

---

## 🛡️ Developer Options & Credentials
1. Open the app and navigate to the **Medical ID / Profile Screen** (third navigation tab).
2. Tap the **avatar image 5 times** to unlock **Developer Mode**.
3. Under the newly revealed *Developer Tools* section, you can configure your custom **OpenRouter API Key** to enable online cloud model triaging.

---

## 🚨 Clinical Disclaimer
> **IMPORTANT:** Pocket Swasth AI is designed purely as an autonomous supportive triage tool for educational and diagnostic-support purposes. It is *not* a replacement for real physical clinical assessments, physical physician diagnoses, or professional emergency services. In case of life-threatening events, immediately contact your local emergency services (102 / 112 / 911).

---

*Designed & developed with absolute clinical precision, high privacy standards, and beautiful aesthetics. 🩻🩺*
