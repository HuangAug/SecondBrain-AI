from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "SecondBrain"
    debug: bool = True
    secret_key: str = "change-me"

    database_url: str = "postgresql+asyncpg://secondbrain:secondbrain@localhost:5432/secondbrain"
    redis_url: str = "redis://localhost:6379/0"

    jwt_secret_key: str = "change-me-jwt"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080

    deepseek_api_key: str = ""
    deepseek_base_url: str = "https://api.deepseek.com/v1"
    deepseek_model: str = "deepseek-chat"

    qwen_api_key: str = ""
    qwen_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    qwen_model: str = "qwen-max"
    qwen_embedding_model: str = "text-embedding-v3"

    default_llm_provider: str = "deepseek"

    cos_secret_id: str = ""
    cos_secret_key: str = ""
    cos_bucket: str = ""
    cos_region: str = "ap-shanghai"

    sentry_dsn: str = ""
    dev_mode: bool = True

    upload_dir: str = "uploads"
    max_upload_size_mb: int = 20


settings = Settings()
