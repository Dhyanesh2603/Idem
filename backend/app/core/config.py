from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Obsidian Slate Backend"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = "obsidian_slate_production_grade_secret_key_gdg_2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    DATABASE_URL: str = "sqlite:///./obsidian_slate_server.db"

    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env")

settings = Settings()
