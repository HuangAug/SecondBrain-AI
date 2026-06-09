"""端到端联调脚本。用法: python scripts/integration_test.py [--base http://127.0.0.1:8001]"""
import argparse
import json
import sys
import time

import httpx

BASE = "http://127.0.0.1:8001"
PHONE = "13700137000"
CODE = "123456"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default=BASE)
    args = parser.parse_args()
    base = args.base.rstrip("/")

    with httpx.Client(base_url=base, timeout=60.0) as client:
        print("1. Health")
        r = client.get("/health")
        assert r.status_code == 200, r.text
        print(f"   OK: {r.json()}")

        print("2. Login")
        client.post("/api/v1/auth/send-code", json={"phone": PHONE})
        r = client.post("/api/v1/auth/verify", json={"phone": PHONE, "code": CODE})
        assert r.status_code == 200, r.text
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f"   OK: user={r.json()['nickname']}")

        print("3. Chat stream")
        full = ""
        conv_id = None
        with client.stream(
            "POST",
            "/api/v1/chat/stream",
            headers=headers,
            json={"message": "用一句话解释什么是微积分"},
        ) as resp:
            assert resp.status_code == 200, resp.text
            for line in resp.iter_lines():
                if not line.startswith("data: "):
                    continue
                data = json.loads(line[6:])
                full += data.get("content", "")
                if data.get("done"):
                    conv_id = data.get("conversation_id")
        assert full, "empty stream response"
        print(f"   OK: conv={conv_id}, reply={full[:60]}...")

        print("4. Study plan")
        r = client.post(
            "/api/v1/plans",
            headers=headers,
            json={"goal": "学习线性代数", "level": "beginner", "duration_days": 3},
        )
        assert r.status_code == 200, r.text
        plan = r.json()
        assert len(plan["tasks"]) >= 1
        print(f"   OK: {len(plan['tasks'])} tasks")

        print("5. Document upload + RAG")
        content = "# Python 笔记\n\nPython 是解释型语言，语法简洁。\n"
        files = {"file": ("note.txt", content.encode("utf-8"), "text/plain")}
        r = client.post("/api/v1/documents/upload", headers=headers, files=files)
        assert r.status_code == 200, r.text
        doc_id = r.json()["id"]
        for _ in range(10):
            r = client.get(f"/api/v1/documents/{doc_id}", headers=headers)
            if r.json()["status"] == "ready":
                break
            time.sleep(0.5)
        assert r.json()["status"] == "ready", r.text
        print(f"   OK: doc ready, chunks={r.json()['chunk_count']}")

        r = client.post(
            "/api/v1/conversations",
            headers=headers,
            json={"type": "rag", "title": "文档问答", "document_id": doc_id},
        )
        assert r.status_code == 200, r.text
        rag_conv_id = r.json()["id"]

        rag_reply = ""
        with client.stream(
            "POST",
            "/api/v1/chat/stream",
            headers=headers,
            json={"message": "Python是什么类型的语言？", "conversation_id": rag_conv_id},
        ) as resp:
            assert resp.status_code == 200, resp.text
            for line in resp.iter_lines():
                if not line.startswith("data: "):
                    continue
                data = json.loads(line[6:])
                rag_reply += data.get("content", "")
        assert rag_reply, "empty rag response"
        print(f"   OK: rag reply={rag_reply[:80]}...")

    print("\n=== 全部联调通过 ===")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nFAILED: {e}", file=sys.stderr)
        sys.exit(1)
