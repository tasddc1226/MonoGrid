# [PRD] Project: MonoGrid (모노그리드) - iOS Native Habit Tracker

## 1. 프로젝트 개요
* **앱 이름:** MonoGrid
* **플랫폼:** iOS 17.0+ (iPhone Only)
* **핵심 가치:** 3개의 핵심 습관만을 관리하며, 앱 실행 없이 iOS 네이티브 기능(위젯, 제어센터, 단축어)을 통해 기록하는 "Invisible Tracking".
* **디자인 컨셉:** GitHub Contribution Graph 스타일의 미니멀리즘.
* **개발 목표:** 복잡한 온보딩 없이 설치 즉시 사용 가능한 단일 뷰 기반 앱.

---

## 2. 기술 스택 (Tech Stack)
* **Language:** Swift 5.9+
* **Framework:** SwiftUI
* **Data Persistence:** SwiftData (권장) or CoreData
* **Native Features:** * WidgetKit (Interactive Widgets)
    * AppIntents (Shortcuts, Control Center, Action Button support)
    * HealthKit (Optional: 만보 걷기 자동 연동)
    * Charts (Swift Charts for visualization - Optional)

---

## 3. 데이터 모델 (Data Model - SwiftData Schema)

### A. Model: `Habit` (습관 메타데이터)
* 사용자는 최대 3개의 `Habit`만 생성 가능.
* **Properties:**
    * `id`: UUID (Unique Identifier)
    * `title`: String (습관 이름, 예: 독서, 운동)
    * `colorHex`: String (테마 컬러 Hex 코드)
    * `iconSymbol`: String (SF Symbols 시스템 이름)
    * `orderIndex`: Int (0, 1, 2 - 정렬 순서)
    * `isHealthKitLinked`: Boolean (HealthKit 연동 여부)
    * `createdAt`: Date

### B. Model: `HabitLog` (일일 기록)
* **Properties:**
    * `id`: UUID
    * `date`: Date (시간 제외, yyyy-MM-dd 기준)
    * `isCompleted`: Boolean (완료 여부)
    * `habitID`: UUID (Foreign Key relation to `Habit`)

---

## 4. 핵심 기능 명세 (Functional Requirements)

### 4-1. 습관 관리 (CRUD)
* 앱 최초 실행 시 기본 3개 슬롯이 비어있거나, 예시(Placeholder)로 표시.
* 습관 추가/수정 시: 이름, 아이콘(SF Symbol Picker), 메인 컬러(Preset 6종) 선택.
* **제약 사항:** 습관은 최대 3개까지만 생성 가능 (삭제 후 생성 가능).

### 4-2. 그리드 렌더링 (The Logic)
* **기간:** 오늘을 기준으로 과거 365일(혹은 52주) 데이터를 표시.
* **UI 구성:** 7행(월~일) x N열(주)의 격자 형태.
* **색상 로직:** * 데이터 없음: 옅은 회색 (`Color.gray.opacity(0.1)`)
    * 완료됨: 사용자가 지정한 `Habit Color`
    * (고도화 시) 연속 달성(Streak) 일수에 따라 Opacity 조절 (예: 1일=0.4, 3일+=0.7, 7일+=1.0).

### 4-3. 인터랙션 (Action)
* **탭 제스처:** * 오늘 날짜의 그리드 셀(Cell)을 탭하면 `Complete` <-> `Incomplete` 토글.
    * 과거 날짜 수정 가능 (옵션).
* **Haptic Feedback:** 토글 성공 시 `UIImpactFeedbackGenerator(.medium)` 발생.

---

## 5. 네이티브 기능 명세 (Native Integrations) - **핵심 개발 항목**

### 5-1. App Intents (단축어 & 제어 센터)
* **Intent Name:** `ToggleHabitIntent`
* **Parameters:** `HabitEntity` (사용자가 설정한 습관 중 선택)
* **기능:** 외부에서 실행 시 해당 습관의 '오늘' 기록을 토글하고 결과를 리턴.
* **활용처:** iOS 18 제어 센터 위젯, Siri 음성 명령, 아이폰 15 Pro 액션 버튼.

### 5-2. Interactive Widgets (홈 화면)
* **Small Widget:** 습관 1개의 오늘 상태 표시 + 클릭 시 `ToggleHabitIntent` 실행.
* **Medium Widget:** 습관 3개의 리스트 + 각 습관별 체크 버튼 (앱 실행 없이 위젯 내에서 즉시 완료 처리).
* **Large Widget:** 3개 습관의 GitHub 스타일 미니 그리드 노출 + 하단에 체크 버튼.

### 5-3. Lock Screen Widgets
* **Circular Widget:** 특정 습관의 아이콘 표시 + 완료 시 채워지는 링(Ring) 형태.
* **Inline Widget:** "오늘 남은 습관: N개" 텍스트 표시.

---

## 6. UI/UX 디자인 가이드 (Views)

### 6-1. Main Dashboard (HomeView)
* **Header:** 오늘 날짜, 심플한 인사말.
* **Body:** `VStack`으로 쌓인 3개의 `HabitCardView`.
    * `HabitCardView` 내부:
        * 좌측: 습관 아이콘 + 이름
        * 우측: 커다란 체크 버튼 (오늘 완료 여부)
        * 하단: 최근 2주~1달 간의 미니 히트맵(Grid)
* **Footer:** 설정 버튼 (톱니바퀴).

### 6-2. Settings / Edit View
* 습관 3개 슬롯 각각의 편집 모드 진입.
* HealthKit 권한 요청 버튼 (만보 연동 시).
* 데이터 초기화, 앱 버전 정보.

---

## 7. 프로젝트 아키텍처 및 폴더 구조 (Project Structure)

```text
MonoGrid/
├── App/
│   ├── MonoGridApp.swift (Main Entry)
│   └── PersistenceController.swift (SwiftData Container Setup)
├── Models/
│   ├── Habit.swift
│   └── HabitLog.swift
├── ViewModels/
│   └── HabitViewModel.swift (Business Logic, Fetching, Toggling)
├── Views/
│   ├── HomeView.swift
│   ├── Components/
│   │   ├── HabitCardView.swift
│   │   └── GitHubGridView.swift (Grid Rendering Logic)
│   └── SettingsView.swift
├── Extensions/
│   ├── Date+Extensions.swift (Calendar calculation helper)
│   └── Color+Extensions.swift
├── Intents/ (App Intents for Native Features)
│   ├── ToggleHabitIntent.swift
│   └── HabitEntity.swift
└── Widgets/ (Widget Extension Target)
    ├── MonoGridWidget.swift
    └── MonoGridWidgetBundle.swift

8. 개발 시 유의사항 (Checklist for Dev)

- SwiftData @Model: 데이터 변경 시 위젯이 즉시 갱신되도록 WidgetCenter.shared.reloadAllTimelines()를 데이터 저장 시점에 반드시 호출할 것.
- Date Handling: 시간대(Timezone) 문제를 방지하기 위해 모든 날짜 저장은 시간을 제거한 startOfDay를 기준으로 할 것.
- App Groups: 위젯과 본 앱이 데이터를 공유하기 위해 반드시 App Group Capability를 추가하고 SwiftData 컨테이너를 해당 경로로 설정할 것.
- iOS 17 Compatibility: #Preview 매크로를 사용하여 UI 개발 속도를 높일 것.

9. 1차 MVP 배포 체크리스트

[ ] 앱 아이콘 (미니멀한 그리드 형상)

[ ] 3개 습관 생성 및 SwiftData 저장 확인

[ ] 메인 화면에서 깃허브 스타일 그리드 정상 렌더링 확인

[ ] 홈 화면 위젯 추가 및 인터랙티브 토글 동작 확인

[ ] 단축어 앱에서 '습관 체크' 동작 확인