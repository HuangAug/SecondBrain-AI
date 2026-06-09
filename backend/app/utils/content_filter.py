BLOCKED_KEYWORDS = [
    "制作炸弹",
    "恐怖袭击",
    "自杀方法",
]

SENSITIVE_RESPONSE = "抱歉，这个问题超出了我的辅导范围。请换一个与学习相关的问题吧。"


def is_content_safe(text: str) -> bool:
    text_lower = text.lower()
    return not any(kw in text_lower for kw in BLOCKED_KEYWORDS)
