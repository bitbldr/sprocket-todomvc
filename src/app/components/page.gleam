import app/app_context.{type AppContext}
import app/components/clock.{ClockProps, clock}
import app/components/counter.{CounterProps, counter}
import app/components/hello_button.{HelloButtonProps, hello_button}
import sprocket/component.{component, render}
import sprocket/context.{type Context}
import sprocket/html/attributes.{
  autocomplete, class, href, id, name, placeholder,
}

import sprocket/html/elements.{
  a, button, div, footer, form, h1, header, input, li, section, span, strong,
  text, ul,
}

pub type PageProps {
  PageProps(app: AppContext, path: String)
}

pub fn page(ctx: Context, _props: PageProps) {
  render(
    ctx,
    div([id("app"), class("container mx-auto px-4")], [
      div([class("todomvc-wrapper")], [
        section([class("todoapp")], [
          header([class("header")], [
            h1([], [text("todos")]),
            form([id("todo-form"), href("/todos")], [
              input([
                class("new-todo"),
                placeholder("What needs to be complete?"),
                name("content"),
                autocomplete("off"),
              ]),
            ]),
          ]),
          section([class("main")], [
            ul([id("todo-list"), class("todo-list")], []),
          ]),
          footer([class("footer")], [
            span([id("todo-count"), class("todo-count")], [
              strong([], [text("0")]),
              text(" todos left"),
            ]),
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
