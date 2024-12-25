import gleam/bool.{guard}
import gleam/option.{None, Some, values}
import sprocket/component.{render}
import sprocket/context.{type Context}
import sprocket/hooks.{handler, state}
import sprocket/html/attributes.{checked, class, classes, input_type}
import sprocket/html/elements.{a, button, div, form, input, label, li, text}
import sprocket/html/events.{on_blur, on_click, on_keydown}

pub type ItemProps {
  ItemProps(
    completed: Bool,
    content: String,
    id: Int,
    on_mark: fn() -> Nil,
    on_delete: fn() -> Nil,
  )
}

pub fn item(ctx: Context, props: ItemProps) {
  let ItemProps(completed, content, id, on_mark, on_delete) = props

  use ctx, is_editing, set_is_editing <- state(ctx, False)

  use ctx, toggle_completion <- handler(ctx, fn(_) { on_mark() })
  use ctx, set_editing <- handler(ctx, fn(_) { set_is_editing(True) })
  use ctx, clear_editing <- handler(ctx, fn(_) { set_is_editing(True) })
  use ctx, delete <- handler(ctx, fn(_) { on_delete() })

  let item_class = case completed {
    True -> "completed"
    False -> ""
  }

  render(
    ctx,
    li([class(item_class)], [
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
        a([class("edit-btn"), on_click(set_editing)], [text("✎")]),
        button([class("destroy"), on_click(delete)], []),
      ]),
      input([
        classes([
          Some("edit"),
          guard(is_editing, Some("editing"), fn() { None }),
        ]),
        on_blur(clear_editing),
        on_keydown(set_editing),
      ]),
    ]),
  )
}
