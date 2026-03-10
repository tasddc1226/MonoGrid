#!/usr/bin/env python3
"""
App Store Connect API Client for MonoGrid
리뷰 모니터링 + 매출/다운로드 리포트
"""

import jwt
import time
import json
import httpx
from pathlib import Path
from datetime import datetime, timedelta

CONFIG_DIR = Path(__file__).parent.parent / "config"

APP_ID = "6758255486"  # MonoGrid


def get_token():
    """JWT 토큰 생성"""
    env = {}
    env_path = CONFIG_DIR / ".env"
    for line in env_path.read_text().strip().split("\n"):
        if "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()

    key_path = CONFIG_DIR / "AuthKey.p8"
    private_key = key_path.read_text()

    now = int(time.time())
    payload = {
        "iss": env["ASC_ISSUER_ID"],
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload, private_key, algorithm="ES256",
        headers={"kid": env["ASC_KEY_ID"], "typ": "JWT"}
    )


def get_headers():
    return {"Authorization": f"Bearer {get_token()}"}


def fetch_reviews(since_days=7):
    """최근 리뷰 조회"""
    headers = get_headers()
    r = httpx.get(
        f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/customerReviews",
        headers=headers,
        params={"limit": 50, "sort": "-createdDate"},
    )
    if r.status_code != 200:
        return []

    reviews = []
    cutoff = datetime.utcnow() - timedelta(days=since_days)
    for rv in r.json().get("data", []):
        a = rv["attributes"]
        created = datetime.fromisoformat(a["createdDate"].replace("Z", "+00:00"))
        if created.replace(tzinfo=None) < cutoff:
            break
        reviews.append({
            "id": rv["id"],
            "rating": a.get("rating", 0),
            "title": a.get("title", ""),
            "body": a.get("body", ""),
            "reviewer": a.get("reviewerNickname", "익명"),
            "created": a["createdDate"],
            "territory": a.get("territory", ""),
        })
    return reviews


def fetch_app_info():
    """앱 기본 정보"""
    headers = get_headers()
    r = httpx.get(
        f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions",
        headers=headers,
        params={"limit": 1, "filter[platform]": "IOS"},
    )
    if r.status_code != 200:
        return {}
    versions = r.json().get("data", [])
    if not versions:
        return {}
    a = versions[0]["attributes"]
    return {
        "version": a.get("versionString"),
        "state": a.get("appStoreState"),
    }


def check_new_reviews():
    """새 리뷰 체크 (마지막 체크 이후)"""
    state_file = CONFIG_DIR / "review_state.json"
    last_check = None
    if state_file.exists():
        state = json.loads(state_file.read_text())
        last_check = state.get("last_review_id")

    reviews = fetch_reviews(since_days=30)
    if not reviews:
        return []

    new_reviews = []
    for rv in reviews:
        if rv["id"] == last_check:
            break
        new_reviews.append(rv)

    # 상태 저장
    if reviews:
        state_file.write_text(json.dumps({
            "last_review_id": reviews[0]["id"],
            "last_check": datetime.utcnow().isoformat(),
        }))

    return new_reviews


def generate_reply_draft(rv):
    """리뷰 답변 초안 생성"""
    rating = rv["rating"]
    name = rv["reviewer"]

    if rating >= 5:
        return (
            f"{name}님, 소중한 리뷰 감사합니다! 🙏\n"
            f"MonoGrid를 좋아해주셔서 정말 기쁩니다. "
            f"주변에도 추천해주시면 큰 힘이 됩니다!\n"
            f"앞으로도 더 좋은 앱으로 보답하겠습니다. ⭐"
        )
    elif rating >= 4:
        return (
            f"{name}님, 리뷰 감사합니다! 🙏\n"
            f"더 나은 경험을 위해 어떤 부분을 개선하면 좋을지 "
            f"알려주시면 적극 반영하겠습니다!\n"
            f"감사합니다. 😊"
        )
    else:
        return (
            f"{name}님, 불편을 드려 죄송합니다. 🙇\n"
            f"말씀해주신 부분 꼭 개선하겠습니다. "
            f"구체적인 피드백은 suyoung.yang@plabfootball.com으로 "
            f"보내주시면 빠르게 도움드리겠습니다.\n"
            f"감사합니다."
        )


def format_review(rv):
    """리뷰 디스코드 포맷"""
    stars = "⭐" * rv["rating"]
    draft = generate_reply_draft(rv)
    lines = [
        f"## 📱 MonoGrid 새 리뷰!",
        f"",
        f"**{stars}** — {rv['title']}",
        f"> {rv['body'][:300]}",
        f"",
        f"— {rv['reviewer']} ({rv['territory']}) · {rv['created'][:10]}",
        f"",
        f"### 💬 답변 초안",
        f"```",
        draft,
        f"```",
        f"*승인하시면 게시합니다*",
    ]
    return "\n".join(lines)


def format_review_summary(reviews):
    """리뷰 요약"""
    if not reviews:
        return "📱 MonoGrid: 새 리뷰 없음"
    lines = [f"## 📱 MonoGrid 새 리뷰 {len(reviews)}건\n"]
    for rv in reviews:
        stars = "⭐" * rv["rating"]
        lines.append(f"{stars} **{rv['title']}** — {rv['reviewer']}")
        if rv["body"]:
            lines.append(f"> {rv['body'][:100]}...")
        lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    cmd = sys.argv[1] if len(sys.argv) > 1 else "info"

    if cmd == "info":
        info = fetch_app_info()
        print(f"MonoGrid v{info.get('version')} — {info.get('state')}")
        reviews = fetch_reviews(since_days=365)
        print(f"리뷰: {len(reviews)}건")
        if reviews:
            avg = sum(r["rating"] for r in reviews) / len(reviews)
            print(f"평균 별점: {avg:.1f}")
        for rv in reviews[:3]:
            print(f"  {'⭐'*rv['rating']} {rv['title']} — {rv['reviewer']}")

    elif cmd == "check":
        new = check_new_reviews()
        if new:
            print(format_review_summary(new))
        else:
            print("새 리뷰 없음")

    elif cmd == "reviews":
        reviews = fetch_reviews(since_days=int(sys.argv[2]) if len(sys.argv) > 2 else 30)
        for rv in reviews:
            print(f"{'⭐'*rv['rating']} {rv['title']} — {rv['reviewer']} ({rv['created'][:10]})")
            print(f"  {rv['body'][:200]}")
