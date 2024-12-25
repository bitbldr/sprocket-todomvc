import app/utils/common.{mist_response}
import gleam/bytes_tree
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/list
import gleam/result
import gleam/string
import mist.{type ResponseData}
import simplifile

pub fn middleware(
  request: Request(in),
  next: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  let request_path = case request.path {
    "/" -> "/index.html"
    path -> path
  }

  let path =
    request_path
    |> string.replace(each: "..", with: "")
    |> string.replace(each: "//", with: "/")
    |> string.append("/static", _)
    |> string.append(priv_directory(), _)

  let file_contents =
    path
    |> simplifile.read_bits
    |> result.replace_error(Nil)
    |> result.map(bytes_tree.from_bit_array)

  let extension =
    path
    |> string.split(on: ".")
    |> list.last
    |> result.unwrap("")

  case file_contents {
    Ok(bits) -> {
      let content_type = case extension {
        "html" -> "text/html"
        "css" -> "text/css"
        "js" -> "application/javascript"
        "png" | "jpg" -> "image/jpeg"
        "gif" -> "image/gif"
        "svg" -> "image/svg+xml"
        "ico" -> "image/x-icon"
        _ -> "octet-stream"
      }
      Response(200, [#("content-type", content_type)], bits)
      |> mist_response()
    }
    Error(_) -> next()
  }
}

@external(erlang, "sprocket_todomvc_ffi", "priv_directory")
pub fn priv_directory() -> String
