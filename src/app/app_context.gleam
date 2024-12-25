import app/database

pub type AppContext {
  AppContext(secret_key_base: String, db: database.Connection, user_id: Int)
}
