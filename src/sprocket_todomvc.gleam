import app/app_context.{AppContext}
import app/database
import app/router
import app/utils/logger
import envoy
import gleam/erlang/process
import gleam/int
import gleam/result
import mist

const db_name = "todomvc.sqlite3"

pub fn main() {
  logger.configure_backend(logger.Info)

  let secret_key_base = load_secret_key_base()
  let port = load_port()

  let assert Ok(_) = database.with_connection(db_name, database.migrate_schema)

  use db <- database.with_connection(db_name)

  let app = AppContext(secret_key_base: secret_key_base, db: db, user_id: 0)

  let assert Ok(_) =
    router.handle_request(_, app)
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn load_port() -> Int {
  envoy.get("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}

fn load_secret_key_base() -> String {
  envoy.get("SECRET_KEY_BASE")
  |> result.unwrap("secret")
}
