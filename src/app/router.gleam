import app/app_context.{type AppContext, AppContext}
import app/components/page.{PageProps, page}
import app/layouts/page_layout.{page_layout}
import app/static
import app/user
import app/utils/common.{mist_response}
import app/utils/csrf
import app/utils/logger
import gleam/bit_array
import gleam/bytes_tree
import gleam/crypto
import gleam/erlang
import gleam/http.{Get}
import gleam/http/cookie
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}
import mist_sprocket.{view}

pub fn handle_request(
  request: Request(Connection),
  app: AppContext,
) -> Response(ResponseData) {
  use <- log_request(request)
  use <- rescue_crashes()
  use app <- authenticate(request, app)
  use <- static.middleware(request)
  use <- made_with_gleam()

  case request.method, request.path_segments(request) {
    Get, _ ->
      view(
        request,
        page_layout("Sprocket TodoMVC", csrf.generate(app.secret_key_base)),
        page,
        fn(_) { PageProps(app, path: request.path) },
        csrf.validate(_, app.secret_key_base),
        None,
      )

    _, _ ->
      not_found()
      |> response.map(bytes_tree.from_string)
      |> mist_response()
  }
}

pub fn log_request(
  req: Request(Connection),
  handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  let response = handler()
  [
    int.to_string(response.status),
    " ",
    string.uppercase(http.method_to_string(req.method)),
    " ",
    req.path,
  ]
  |> string.concat
  |> logger.info
  response
}

const uid_cookie = "uid"

/// Load the user from the `uid` cookie if set, otherwise create a new user row
/// and assign that in the response cookies.
///
/// The `uid` cookie is signed to prevent tampering.
pub fn authenticate(
  req: Request(Connection),
  app: AppContext,
  next: fn(AppContext) -> Response(ResponseData),
) -> Response(ResponseData) {
  let id =
    get_cookie(req, app.secret_key_base, uid_cookie)
    |> result.try(int.parse)
    |> option.from_result

  let #(id, new_user) = case id {
    option.None -> {
      logger.info("Creating a new user")
      let user = user.insert_user(app.db)
      #(user, True)
    }
    option.Some(id) -> #(id, False)
  }
  let app = AppContext(..app, user_id: id)
  let resp = next(app)

  case new_user {
    True -> {
      let id = int.to_string(id)
      let year = 60 * 60 * 24 * 365
      set_cookie(resp, app.secret_key_base, uid_cookie, id, year)
    }
    False -> resp
  }
}

fn get_cookie(
  req: Request(Connection),
  secret_key_base: String,
  name: String,
) -> Result(String, Nil) {
  use value <- result.try(
    req
    |> request.get_cookies
    |> list.key_find(name),
  )
  use value <- result.try(
    crypto.verify_signed_message(value, <<secret_key_base:utf8>>),
  )
  bit_array.to_string(value)
}

pub fn set_cookie(
  response response: Response(ResponseData),
  secret_key_base secret_key_base: String,
  name name: String,
  value value: String,
  max_age max_age: Int,
) -> Response(ResponseData) {
  let attributes =
    cookie.Attributes(
      ..cookie.defaults(http.Https),
      max_age: option.Some(max_age),
    )
  let value =
    crypto.sign_message(<<value:utf8>>, <<secret_key_base:utf8>>, crypto.Sha512)
  response
  |> response.set_cookie(name, value, attributes)
}

fn made_with_gleam(
  next: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  let response = next()
  response
  |> response.prepend_header("made-with", "Gleam")
}

pub fn method_not_allowed() -> Response(String) {
  response.new(405)
  |> response.set_body("Method not allowed")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn not_found() -> Response(String) {
  response.new(404)
  |> response.set_body("Page not found")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn bad_request() -> Response(String) {
  response.new(400)
  |> response.set_body("Bad request. Please try again")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn internal_server_error() -> Response(String) {
  response.new(500)
  |> response.set_body("Internal Server Error")
  |> response.prepend_header("content-type", "text/plain")
}

pub fn rescue_crashes(
  handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  case erlang.rescue(handler) {
    Ok(response) -> response
    Error(error) -> {
      logger.error(string.inspect(error))

      internal_server_error()
      |> response.map(bytes_tree.from_string)
      |> mist_response()
    }
  }
}
