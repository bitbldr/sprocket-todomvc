import app/utils/logger
import gleam/io
import sqlight

pub type AppError {
  NotFound
  MethodNotAllowed
  UserNotFound
  BadRequest
  UnprocessableEntity
  ContentRequired
  SqlightError(sqlight.Error)
}

pub fn humanize(error: AppError) -> String {
  case error {
    NotFound -> "Not found"
    MethodNotAllowed -> "Method not allowed"
    UserNotFound -> "User not found"
    BadRequest -> "Bad request"
    UnprocessableEntity -> "Unprocessable entity"
    ContentRequired -> "Content required"
    SqlightError(e) -> {
      logger.error("Sqlight error")
      io.debug(e)

      "Internal server error"
    }
  }
}
