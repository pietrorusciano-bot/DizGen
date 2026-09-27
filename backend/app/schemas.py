from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GenerationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    name: str
    start_year: int
    end_year: int


class TermOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    language: str
    term: str
    definition: str
    example: str
    source: str
    source_url: str
    generations: list[GenerationOut]


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    birth_year: int
    gender: str | None
    generation: GenerationOut | None


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class RegisterRequest(BaseModel):
    username: str
    password: str
    birth_year: int
    gender: str | None = None


class ProfileUpdateRequest(BaseModel):
    gender: str | None = None


class LoginRequest(BaseModel):
    username: str
    password: str


class AnalyzeRequest(BaseModel):
    text: str
    language: str = "it"


class TermMatch(BaseModel):
    id: int
    term: str
    definition: str
    example: str
    source: str
    source_url: str
    using_generations: list[str]
    familiar: bool


class AnalyzeResponse(BaseModel):
    language: str
    matches: list[TermMatch]
