from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, UserResponse, Token
from app.services.auth_service import register_user, authenticate_user, create_access_token

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=Token,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account"
)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Register a new user with name, email, and password.
    Returns the JWT access token and user profile upon successful registration.
    """
    user = register_user(db, user_data)
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.post(
    "/login",
    response_model=Token,
    summary="User login with email and password"
)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """
    Authenticate user credentials and issue a new JWT access token.
    """
    user = authenticate_user(db, credentials.email, credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current authenticated user profile"
)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """
    Fetch the currently authenticated user's profile details.
    """
    return UserResponse.model_validate(current_user)
