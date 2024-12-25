import app/app_context.{type AppContext}
import app/components/item.{ItemProps, item}
import app/database
import app/error
import app/items.{type Item}
import app/utils/logger
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import sprocket/component.{component, render}
import sprocket/context.{type Context}
import sprocket/hooks.{type Cmd, client, handler, reducer}
import sprocket/html/attributes.{
  autocomplete, class, href, id, name, placeholder,
}
import sprocket/html/elements.{
  a, button, div, footer, form, h1, header, input, keyed, li, section, span,
  strong, text, ul,
}
import sprocket/html/events

type Model {
  Model(items: Option(List(Item)))
}

type Msg {
  LoadItems(Int, database.Connection)
  ItemsLoaded(List(Item))
}

fn init(user_id: Int, db: database.Connection) -> #(Model, List(Cmd(Msg))) {
  #(Model(None), [load_items(user_id, db)])
}

fn load_items(user_id: Int, db: database.Connection) -> Cmd(Msg) {
  fn(dispatch) { dispatch(ItemsLoaded(items.list_items(user_id, db))) }
}

fn update(_model: Model, msg: Msg) {
  case msg {
    LoadItems(user_id, db) -> #(Model(None), [load_items(user_id, db)])
    ItemsLoaded(items) -> #(Model(Some(items)), [])
  }
}

pub type PageProps {
  PageProps(app: AppContext, path: String)
}

pub fn page(ctx: Context, props: PageProps) {
  let PageProps(app, _path) = props

  use ctx, Model(items), dispatch <- reducer(
    ctx,
    init(app.user_id, app.db),
    update,
  )

  let refresh_items = fn() { dispatch(LoadItems(app.user_id, app.db)) }

  use ctx, client_form, dispatch_client_form <- client(ctx, "FormControl", None)

  use ctx, create_item_on_submit <- handler(ctx, fn(e) {
    case events.decode_form_data(e) {
      Ok(data) -> {
        case dict.get(data, "content") {
          Ok(value) -> {
            create_item(value, app, refresh_items)
            let assert Ok(_) = dispatch_client_form("reset", None)

            Nil
          }
          Error(_) -> Nil
        }
      }
      Error(_) -> Nil
    }
  })

  let todo_count =
    items
    |> option.map(fn(items) {
      items
      |> list.count(fn(i) { !i.completed })
    })

  render(
    ctx,
    div([id("app"), class("container mx-auto px-4")], [
      div([class("todomvc-wrapper")], [
        section([class("todoapp")], [
          header([class("header")], [
            h1([], [text("todos")]),
            form(
              [
                id("todo-form"),
                client_form(),
                events.on_submit(create_item_on_submit),
              ],
              [
                input([
                  class("new-todo"),
                  placeholder("What needs to be complete?"),
                  name("content"),
                  autocomplete("off"),
                ]),
              ],
            ),
          ]),
          section([class("main")], [
            ul([id("todo-list"), class("todo-list")], case items {
              Some(items) ->
                list.map(items, fn(i: Item) {
                  keyed(
                    int.to_string(i.id),
                    component(
                      item,
                      ItemProps(
                        id: i.id,
                        content: i.content,
                        completed: i.completed,
                        on_mark: fn() { mark_completed(i, app, refresh_items) },
                        on_delete: fn() {
                          delete_item(i.id, app, refresh_items)
                        },
                      ),
                    ),
                  )
                })
              None -> []
            }),
          ]),
          footer([class("footer")], [
            case todo_count {
              Some(count) ->
                span([id("todo-count"), class("todo-count")], [
                  strong([], [text(int.to_string(count))]),
                  text(" todos left"),
                ])
              None -> span([], [])
            },
            ul([class("filters")], [
              li([], [a([href("/"), class("selected")], [text("All")])]),
              li([], [a([href("/active")], [text("Active")])]),
              li([], [a([href("/completed")], [text("Completed")])]),
            ]),
            button(
              [
                id("clear-completed"),
                class("clear-completed"),
                href("/completed"),
              ],
              [],
            ),
          ]),
        ]),
      ]),
    ]),
  )
}

fn mark_completed(i: Item, app: AppContext, refresh_items: fn() -> Nil) {
  case items.toggle_completion(i.id, app.user_id, app.db) {
    Ok(_) -> refresh_items()
    Error(e) ->
      e
      |> error.humanize()
      |> logger.error()
  }

  Nil
}

fn create_item(content: String, app: AppContext, refresh_cb: fn() -> Nil) {
  case items.insert_item(content, app.user_id, app.db) {
    Ok(_) -> refresh_cb()
    Error(e) ->
      e
      |> error.humanize()
      |> logger.error()
  }
}

fn delete_item(id: Int, app: AppContext, refresh_cb: fn() -> Nil) {
  items.delete_item(id, app.user_id, app.db)

  refresh_cb()
}
