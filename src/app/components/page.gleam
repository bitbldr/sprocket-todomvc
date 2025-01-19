import app/app_context.{type AppContext}
import app/components/item.{ItemProps, item}
import app/database
import app/error
import app/flash.{type Flash, flash_messages}
import app/items.{type Counts, type Item}
import app/page_filter.{type Filter, Active, All, Completed}
import app/utils/logger
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import sprocket/component.{component, render}
import sprocket/context.{type Context}
import sprocket/hooks.{type Cmd, client, reducer}
import sprocket/html/attributes.{
  autocomplete, class, classes, href, id, name, placeholder,
}
import sprocket/html/elements.{
  a, button, div, footer, form, h1, header, input, keyed, li, section, span,
  strong, text, ul,
}
import sprocket/html/events

type Model {
  Loading
  Model(items: List(Item), counts: Counts)
}

type Msg {
  LoadItems(Int, filter: Filter, database.Connection)
  ItemsLoaded(List(Item), Counts)
}

fn init(
  user_id: Int,
  filter: page_filter.Filter,
  db: database.Connection,
) -> #(Model, List(Cmd(Msg))) {
  #(Loading, [load_items(user_id, filter, db)])
}

fn load_items(user_id: Int, filter: Filter, db: database.Connection) -> Cmd(Msg) {
  fn(dispatch) {
    let loaded_items = case filter {
      All -> items.list_items(user_id, db)
      Active -> items.filtered_items(user_id, False, db)
      Completed -> items.filtered_items(user_id, True, db)
    }

    let counts = items.get_counts(user_id, db)

    dispatch(ItemsLoaded(loaded_items, counts))
  }
}

fn update(model: Model, msg: Msg) {
  case msg {
    LoadItems(user_id, filter, db) -> #(model, [load_items(user_id, filter, db)])
    ItemsLoaded(items, counts) -> #(Model(items, counts), [])
  }
}

pub type PageProps {
  PageProps(app: AppContext, path: String)
}

pub fn page(ctx: Context, props: PageProps) {
  let PageProps(app, path) = props

  let filter = page_filter.filter_from_path(path)

  use ctx, model, dispatch <- reducer(
    ctx,
    init(app.user_id, filter, app.db),
    update,
  )

  use ctx, flash <- flash.flash(ctx)

  let refresh_items = fn() { dispatch(LoadItems(app.user_id, filter, app.db)) }

  use ctx, client_form, dispatch_client_form <- client(ctx, "FormControl", None)

  let create_item_on_submit = fn(e) {
    case events.decode_form_data(e) {
      Ok(data) -> {
        case dict.get(data, "content") {
          Ok(value) -> {
            create_item(value, app, flash, refresh_items)
            let _ = dispatch_client_form("reset", None)

            Nil
          }
          Error(_) -> Nil
        }
      }
      Error(_) -> Nil
    }
  }

  // render loading message until the model is loaded, then unpack items and counts
  use items, counts <- render_loading_until(ctx, model)

  render(
    ctx,
    div([id("app"), class("container mx-auto px-4")], [
      flash_messages(flash),
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
            ul(
              [id("todo-list"), class("todo-list")],
              list.map(items, fn(i: Item) {
                keyed(
                  int.to_string(i.id),
                  component(
                    item,
                    ItemProps(
                      content: i.content,
                      completed: i.completed,
                      on_edit: fn(content) {
                        update_item(i.id, content, app, flash, refresh_items)
                        Nil
                      },
                      on_mark: fn() {
                        mark_completed(i, app, flash, refresh_items)
                      },
                      on_delete: fn() { delete_item(i.id, app, refresh_items) },
                    ),
                  ),
                )
              }),
            ),
          ]),
          footer([class("footer")], [
            span([id("todo-count"), class("todo-count")], case filter {
              All -> [
                strong([], [text(int.to_string(counts.active))]),
                text(" todos left"),
              ]
              Active -> [
                strong([], [text(int.to_string(counts.active))]),
                text(" active"),
              ]
              Completed -> [
                strong([], [text(int.to_string(counts.completed))]),
                text(" completed"),
              ]
            }),
            ul([class("filters")], [
              li([], [
                a([href("/"), classes([maybe_selected(All, filter)])], [
                  text("All"),
                ]),
              ]),
              li([], [
                a([href("/active"), classes([maybe_selected(Active, filter)])], [
                  text("Active"),
                ]),
              ]),
              li([], [
                a(
                  [
                    href("/completed"),
                    classes([maybe_selected(Completed, filter)]),
                  ],
                  [text("Completed")],
                ),
              ]),
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

fn render_loading_until(ctx: Context, model: Model, cb) {
  case model {
    Loading ->
      render(
        ctx,
        div([id("app"), class("container mx-auto px-4")], [text("Loading...")]),
      )
    Model(items, counts) -> cb(items, counts)
  }
}

fn maybe_selected(filter: Filter, current: Filter) {
  case filter == current {
    True -> Some("selected")
    False -> None
  }
}

fn mark_completed(
  i: Item,
  app: AppContext,
  flash: Flash,
  refresh_items: fn() -> Nil,
) {
  case items.toggle_completion(i.id, app.user_id, app.db) {
    Ok(_) -> refresh_items()
    Error(e) -> {
      e
      |> error.humanize()
      |> logger.error()

      flash.put(flash.Error, "Failed to toggle completion")
    }
  }

  Nil
}

fn create_item(
  content: String,
  app: AppContext,
  flash: Flash,
  refresh_items: fn() -> Nil,
) {
  case items.insert_item(content, app.user_id, app.db) {
    Ok(_) -> refresh_items()
    Error(e) -> {
      e
      |> error.humanize()
      |> logger.error()

      flash.put(flash.Error, "Failed to create item")
    }
  }
}

fn delete_item(id: Int, app: AppContext, refresh_items: fn() -> Nil) {
  items.delete_item(id, app.user_id, app.db)

  refresh_items()
}

fn update_item(
  id: Int,
  content: String,
  app: AppContext,
  flash: Flash,
  refresh_items: fn() -> Nil,
) {
  case items.update_item(id, app.user_id, content, app.db) {
    Ok(_) -> refresh_items()
    Error(e) -> {
      e
      |> error.humanize()
      |> logger.error()

      flash.put(flash.Error, "Failed to update item")
    }
  }
}
