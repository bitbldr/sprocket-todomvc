import gleam/list
import gleam/result
import gleam/string

pub type Filter {
  All
  Active
  Completed
}

pub fn filter_from_path(path: String) -> Filter {
  path
  |> without_connect()
  |> trim_slashes()
  |> string.split("#")
  |> list.first()
  |> result.then(fn(first) {
    first
    |> string.split("/")
    |> list.first()
  })
  |> result.map(fn(name) {
    case name {
      "active" -> Active
      "completed" -> Completed
      _ -> All
    }
  })
  |> result.unwrap(All)
}

pub fn href(filter: Filter) -> String {
  case filter {
    All -> "/"
    Active -> "/active"
    Completed -> "/completed"
  }
}

fn without_connect(path: String) -> String {
  case string.ends_with(path, "/connect") {
    True -> string.slice(path, 0, string.length(path) - 8)
    False -> path
  }
}

fn trim_slashes(path: String) -> String {
  let path = case string.starts_with(path, "/") {
    True -> string.slice(path, 1, string.length(path))
    False -> path
  }

  let path = case string.ends_with(path, "/") {
    True -> string.slice(path, 0, string.length(path) - 1)
    False -> path
  }

  path
}
