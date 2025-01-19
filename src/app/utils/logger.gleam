import gleam/dynamic.{type Dynamic}

pub type Level {
  Emergency
  Alert
  Critical
  Error
  Warning
  Notice
  Info
  Debug
}

/// Configure the Erlang logger to use the log level and output format that we
/// want, rather than the more verbose Erlang default format.
///
@external(erlang, "sprocket_todomvc_ffi", "configure_logger_backend")
pub fn configure_backend(level: Level) -> Nil

@external(erlang, "logger", "log")
fn erlang_log(a: Level, b: String) -> Dynamic

pub fn log(level: Level, message: String) -> String {
  erlang_log(level, message)

  message
}

pub fn info(message: String) -> String {
  log(Info, message)
}

pub fn warn(message: String) -> String {
  log(Warning, message)
}

pub fn error(message: String) -> String {
  log(Error, message)
}
