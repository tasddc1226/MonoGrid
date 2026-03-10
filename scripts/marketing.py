#!/usr/bin/env python3
"""
MonoGrid 마케팅 콘텐츠 자동 생성
주 2회 크론으로 실행 → 디스코드에 초안 전달
"""

import random
from datetime import datetime

APP_STORE_URL = "https://apps.apple.com/app/id6758255486"
GITHUB_URL = "https://github.com/tasddc1226/MonoGrid"
LANDING_URL = "https://tasddc1226.github.io/MonoGrid/"

# ─── 콘텐츠 풀 ───

TWEET_TEMPLATES = [
    # 기능 소개
    "습관 앱 100개 써보고 결론: 3개만 추적하면 된다.\n\nMonoGrid는 의도적으로 3개만.\nGitHub 잔디처럼 365일 기록이 쌓인다.\n\n{url} #습관 #iOS앱",
    "앱 열지 않고 습관 기록하는 법:\n\n1️⃣ 위젯 탭\n2️⃣ 시리야, 운동 완료\n3️⃣ 제어센터 토글\n\nMonoGrid - 보이지 않는 추적\n{url}",
    "습관 앱에서 가장 중요한 건 '덜어내기'.\n\nMonoGrid:\n✅ 습관 3개만\n✅ 위젯으로 기록\n✅ GitHub 스타일 그리드\n❌ 복잡한 통계\n❌ 소셜 기능\n\n{url}",
    "개발자가 직접 쓰려고 만든 습관 앱.\n\nGitHub 잔디에 영감받아서,\n매일의 기록이 초록색으로 채워진다.\n\nMonoGrid 🟩\n{url}",
    "\"시리야, 독서 완료\"\n\n이 한마디로 오늘의 습관 기록 끝.\nMonoGrid의 Invisible Tracking.\n\n{url} #미니멀 #습관트래커",

    # 스토리텔링
    "66일이면 습관이 된다는데,\n365일 기록을 한눈에 보면 어떨까?\n\nMonoGrid의 연간 그리드가\n당신의 노력을 증명합니다.\n\n{url}",
    "습관 앱 설치 → 2주 후 삭제\n이 사이클 몇 번째?\n\n해결: 앱을 안 열어도 되게 만들었다.\n위젯 탭 한 번이면 끝.\n\nMonoGrid {url}",

    # 개발자 관점
    "SwiftUI + SwiftData로 만든 미니멀 습관 앱.\niCloud 동기화, 위젯, 단축어 지원.\n\n오픈소스도 아닌데 GitHub 잔디가 깔린다 🟩\n\n{url} #indiedev #iOS",
]

REDDIT_TEMPLATES = {
    "r/iOS": {
        "title": "I built a minimalist habit tracker inspired by GitHub's contribution graph",
        "body": """Hey everyone!

I'm a solo developer and I just released **MonoGrid** — a habit tracker that intentionally limits you to **3 habits only**.

**Why only 3?** Research shows focusing on fewer habits leads to higher success rates. Most habit apps let you add unlimited habits, which leads to overwhelm and eventually abandoning the app.

**Key features:**
- 🟩 GitHub-style 365-day contribution grid
- ⚡ Log habits WITHOUT opening the app (widgets, Siri, Control Center)
- ☁️ iCloud sync across devices
- 🌙 Dark mode

**What makes it different:**
The core philosophy is "Invisible Tracking" — you should be able to record your habits with a single tap on a widget or a voice command. The app itself is just for viewing your progress.

Free on the App Store: {url}

I'd love your feedback! What features would you want to see?""",
    },
    "r/productivity": {
        "title": "The 3-habit rule: Why tracking fewer habits leads to better results (+ the app I built for it)",
        "body": """I've been studying habit formation for a while, and one pattern keeps coming up: **people who focus on 3 or fewer habits have significantly higher completion rates**.

So I built an app around this constraint — **MonoGrid**.

It forces you to pick just 3 habits. That's it. No more.

The visualization is inspired by GitHub's contribution graph — a 365-day grid that fills up as you maintain your streaks. There's something deeply satisfying about seeing a year of green squares.

The other key insight: **the less friction, the better**. So I made it possible to log habits from:
- Home screen widgets (one tap)
- Lock screen widgets
- Siri ("Hey Siri, workout done")
- Control Center (iOS 18+)

You literally never have to open the app.

Free for iOS: {url}

Has anyone else found that limiting the number of habits you track actually improves consistency?""",
    },
}

KOREAN_COMMUNITY_TEMPLATES = {
    "disquiet": {
        "title": "MonoGrid - GitHub 잔디에서 영감받은 미니멀 습관 트래커",
        "body": """## 만들게 된 이유

습관 앱을 수십 개 써봤는데, 결국 다 삭제했습니다.
공통적인 문제: **너무 많은 기능, 너무 많은 습관**.

개발자로서 매일 보는 GitHub 잔디처럼,
**3개의 습관만 365일 그리드로 추적**하는 앱을 만들었습니다.

## 핵심 철학: Invisible Tracking

앱을 열지 않고 기록합니다:
- 위젯 탭 한 번
- "시리야, 운동 완료"
- 제어센터 토글

## 기술 스택
- SwiftUI + SwiftData
- WidgetKit + AppIntents
- iCloud 동기화

## 링크
- App Store: {url}
- GitHub: {github}

피드백 환영합니다! 🙏""",
    },
    "geeknews": {
        "title": "Show GN: MonoGrid – 3개 습관만 추적하는 미니멀 iOS 앱",
        "body": """GitHub contribution graph 스타일의 습관 트래커입니다.

의도적으로 습관 3개로 제한했고,
위젯/시리/제어센터로 앱 실행 없이 기록합니다.

SwiftUI + SwiftData, iCloud 동기화 지원.

App Store (무료): {url}""",
    },
}

PRODUCT_HUNT = {
    "tagline": "Track just 3 habits with a GitHub-style contribution grid",
    "description": """MonoGrid is a minimalist habit tracker that intentionally limits you to 3 habits.

🟩 **GitHub-Style Grid** — 365-day contribution graph shows your year at a glance
⚡ **Invisible Tracking** — Log via widgets, Siri, or Control Center without opening the app
🎯 **3 Habits Only** — Research-backed constraint for higher success rates
☁️ **iCloud Sync** — Seamless across all your devices
🌙 **Dark Mode** — Beautiful in any lighting

Built with SwiftUI and SwiftData. Free on the App Store.""",
    "topics": ["Productivity", "iOS", "Health & Fitness", "Habit Tracking"],
    "first_comment": """Hi Product Hunt! 👋

I'm a developer who got tired of habit apps with too many features. I kept adding habits, getting overwhelmed, and eventually deleting the app.

So I built MonoGrid around one simple constraint: **only 3 habits**.

The visualization is inspired by GitHub's contribution graph — there's something uniquely motivating about watching those green squares fill up over a year.

The other key design principle is "Invisible Tracking" — you should never HAVE to open the app. Widgets, Siri Shortcuts, and Control Center integration mean you can log a habit with a single tap or voice command.

I'd love to hear your feedback and suggestions for what to build next!""",
}


def generate_weekly_content():
    """주간 마케팅 콘텐츠 생성"""
    now = datetime.now()
    week_num = now.isocalendar()[1]

    lines = [
        f"# 📣 MonoGrid 마케팅 콘텐츠 (Week {week_num})\n",
        f"생성일: {now.strftime('%Y-%m-%d %H:%M')}\n",
    ]

    # 트윗 2개 랜덤 선택
    tweets = random.sample(TWEET_TEMPLATES, 2)
    lines.append("## 🐦 트위터/X 포스트\n")
    for i, t in enumerate(tweets, 1):
        lines.append(f"### 트윗 {i}")
        lines.append("```")
        lines.append(t.format(url=APP_STORE_URL))
        lines.append("```\n")

    # 커뮤니티 1개 랜덤
    community = random.choice(list(KOREAN_COMMUNITY_TEMPLATES.items()))
    lines.append(f"## 🇰🇷 한국 커뮤니티 ({community[0]})\n")
    lines.append(f"**제목:** {community[1]['title']}\n")
    lines.append("```")
    lines.append(community[1]["body"].format(url=APP_STORE_URL, github=GITHUB_URL))
    lines.append("```\n")

    lines.append("---")
    lines.append("*양대표님 승인 후 게시합니다. 수정 요청도 환영!*")

    return "\n".join(lines)


def generate_producthunt_brief():
    """Product Hunt 런칭 브리프"""
    lines = [
        "# 🚀 Product Hunt 런칭 브리프\n",
        f"**Tagline:** {PRODUCT_HUNT['tagline']}\n",
        f"**Topics:** {', '.join(PRODUCT_HUNT['topics'])}\n",
        "## Description",
        "```",
        PRODUCT_HUNT["description"],
        "```\n",
        "## First Comment (Maker Comment)",
        "```",
        PRODUCT_HUNT["first_comment"],
        "```\n",
        "## 런칭 체크리스트",
        "- [ ] Product Hunt 계정 로그인",
        "- [ ] 앱 아이콘 (240x240) 업로드",
        "- [ ] 스크린샷/GIF 3-5장",
        "- [ ] 런칭 예약 (화요일 00:01 PST 권장)",
        "- [ ] 지인 네트워크에 공유",
        "",
        f"**App Store:** {APP_STORE_URL}",
        f"**Landing Page:** {LANDING_URL}",
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    cmd = sys.argv[1] if len(sys.argv) > 1 else "weekly"

    if cmd == "weekly":
        print(generate_weekly_content())
    elif cmd == "producthunt":
        print(generate_producthunt_brief())
    elif cmd == "reddit":
        for platform, template in REDDIT_TEMPLATES.items():
            print(f"\n## {platform}")
            print(f"**Title:** {template['title']}")
            print(template["body"].format(url=APP_STORE_URL))
