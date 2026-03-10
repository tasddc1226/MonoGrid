#!/usr/bin/env python3
"""
ASO (App Store Optimization) 경쟁 분석
MonoGrid 키워드 및 경쟁앱 추적
"""

# 경쟁앱 목록
COMPETITORS = [
    {"name": "Streaks", "bundleId": "com.crunchy-bagel.Streaks"},
    {"name": "Habitify", "bundleId": "co.unstatic.habitify"},
    {"name": "Done", "bundleId": "com.x-caliber.Done"},
    {"name": "Habit Tracker", "bundleId": "com.simplehabit.tracker"},
    {"name": "Productive", "bundleId": "com.apalon.to-do-list"},
]

# 타겟 키워드 (KR + EN)
TARGET_KEYWORDS_KR = [
    "습관 트래커", "습관 기록", "습관 앱", "미니멀 습관",
    "루틴 관리", "데일리 체크", "위젯 습관",
]
TARGET_KEYWORDS_EN = [
    "habit tracker", "habit grid", "minimal habit",
    "streak tracker", "daily habit", "widget habit tracker",
]

MONOGRID_INFO = {
    "name": "모노그리드",
    "subtitle": "미니멀 습관 트래커",
    "keywords_kr": "습관,트래커,루틴,위젯,미니멀,그리드,기록,체크,일일,관리",
    "keywords_en": "habit,tracker,routine,widget,minimal,grid,streak,daily,check,log",
}


def generate_report():
    """월간 ASO 리포트 생성"""
    lines = [
        "# 📊 MonoGrid ASO 월간 리포트\n",
        "## 현재 메타데이터",
        f"- 앱 이름: {MONOGRID_INFO['name']}",
        f"- 부제목: {MONOGRID_INFO['subtitle']}",
        f"- 키워드(KR): {MONOGRID_INFO['keywords_kr']}",
        f"- 키워드(EN): {MONOGRID_INFO['keywords_en']}",
        "",
        "## 경쟁앱",
    ]
    for c in COMPETITORS:
        lines.append(f"- **{c['name']}** ({c['bundleId']})")

    lines.extend([
        "",
        "## 타겟 키워드",
        "### 한국어",
    ])
    for kw in TARGET_KEYWORDS_KR:
        lines.append(f"- {kw}")
    lines.append("### English")
    for kw in TARGET_KEYWORDS_EN:
        lines.append(f"- {kw}")

    lines.extend([
        "",
        "## 권장 액션",
        "- [ ] 앱스토어 스크린샷 A/B 테스트",
        "- [ ] 부제목 키워드 최적화",
        "- [ ] 릴리즈 노트에 키워드 포함",
        "- [ ] 경쟁앱 새 기능 모니터링",
    ])
    return "\n".join(lines)


if __name__ == "__main__":
    print(generate_report())
