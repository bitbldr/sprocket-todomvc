import gleam/bool.{guard}
import gleam/option.{None, Some, values}
import gleam/string
import sprocket/component.{render}
import sprocket/context.{type Context}
import sprocket/hooks.{client, handler, state}
import sprocket/html/attributes.{
  autocomplete, checked, class, classes, input_type, value,
}
import sprocket/html/elements.{button, div, input, label, li, text}
import sprocket/html/events.{on_blur, on_change, on_click, on_keydown}

pub type ItemProps {
  ItemProps(
    completed: Bool,
    content: String,
    on_edit: fn(String) -> Nil,
    on_mark: fn() -> Nil,
    on_delete: fn() -> Nil,
  )
}

pub fn item(ctx: Context, props: ItemProps) {
  let ItemProps(completed, content, on_edit, on_mark, on_delete) = props

  use ctx, is_editing, set_is_editing <- state(ctx, False)

  use ctx, client_focuser, dispatch_client_focuser <- client(
    ctx,
    "Focuser",
    None,
  )

  use ctx, toggle_completion <- handler(ctx, fn(_) { on_mark() })

  use ctx, start_editing <- handler(ctx, fn(_) {
    set_is_editing(True)
    let assert Ok(_) = dispatch_client_focuser("focus", None)

    Nil
  })

  use ctx, cancel_edit <- handler(ctx, fn(_) { set_is_editing(False) })

  use ctx, update_edit_on_change <- handler(ctx, fn(e) {
    case events.decode_target_value(e) {
      Ok(value) -> {
        value
        |> string.trim()
        |> on_edit()
      }
      _ -> Nil
    }
  })

  use ctx, save_edit_on_enter <- handler(ctx, fn(e) {
    case events.decode_key_event(e) {
      Ok(events.KeyEvent(key: "Enter", ..)) -> {
        set_is_editing(False)
      }
      _ -> Nil
    }
  })

  use ctx, delete <- handler(ctx, fn(_) { on_delete() })

  let item_class = case completed {
    True -> "completed"
    False -> ""
  }

  render(
    ctx,
    li(
      [
        classes([
          Some(item_class),
          guard(is_editing, Some("editing"), fn() { None }),
        ]),
      ],
      [
        div([class("view")], [
          input([
            input_type("checkbox"),
            classes([
              Some("toggle"),
              guard(completed, Some("completed"), fn() { None }),
            ]),
            on_click(toggle_completion),
            ..values([guard(completed, Some(checked()), fn() { None })])
          ]),
          label([], [text(content)]),
          button([class("edit-btn"), on_click(start_editing)], [text("✎")]),
          button([class("destroy"), on_click(delete)], []),
        ]),
        input([
          classes([
            Some("edit"),
            guard(is_editing, Some("editing"), fn() { None }),
          ]),
          autocomplete("off"),
          client_focuser(),
          value(content),
          on_change(update_edit_on_change),
          on_blur(cancel_edit),
          on_keydown(save_edit_on_enter),
        ]),
      ],
    ),
  )
}
