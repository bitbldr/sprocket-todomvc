import app/utils/unique.{type Unique}
import gleam/list
import gleam/option.{Some}
import sprocket/context.{type Context}
import sprocket/hooks.{type Cmd, reducer}
import sprocket/html/attributes.{class, classes}
import sprocket/html/elements.{button_text, div, div_text}
import sprocket/html/events

pub const flash_provider_key = "flash"

pub type FlashLevel {
  Info
  Success
  Warning
  Error
}

pub type FlashId

pub type FlashMessage {
  FlashMessage(id: Unique(FlashId), level: FlashLevel, message: String)
}

pub type Model {
  Model(messages: List(FlashMessage))
}

type Msg {
  Push(FlashLevel, String)
  Clear(Unique(FlashId))
}

pub type Flash {
  Flash(
    get: fn() -> List(FlashMessage),
    put: fn(FlashLevel, String) -> Nil,
    clear: fn(Unique(FlashId)) -> Nil,
  )
}

fn init() -> #(Model, List(Cmd(Msg))) {
  #(Model([]), [])
}

fn update(model: Model, msg: Msg) {
  case msg {
    Push(level, message) -> {
      #(
        Model([FlashMessage(unique.uuid(), level, message), ..model.messages]),
        [],
      )
    }
    Clear(id) -> {
      #(Model(list.filter(model.messages, fn(m) { m.id != id })), [])
    }
  }
}

// Custom hook for flash messages.
pub fn flash(ctx: Context, cb) {
  use ctx, model, dispatch <- reducer(ctx, init(), update)

  cb(
    ctx,
    Flash(
      get: fn() { model.messages },
      put: fn(level, message) { dispatch(Push(level, message)) },
      clear: fn(id) { dispatch(Clear(id)) },
    ),
  )
}

pub fn flash_messages(flash: Flash) {
  let messages = flash.get()

  div(
    [class("flash-messages")],
    list.map(messages, fn(m) {
      div([classes([Some("flash"), Some(flash_class(m.level))])], [
        div_text([class("flash-content")], m.message),
        div([class("flash-close")], [
          // button_text([events.on_click(fn(_) { flash.clear(m.id) })], "x"),
          button_text([], "x"),
        ]),
      ])
    }),
  )
}

fn flash_class(level: FlashLevel) {
  case level {
    Info -> "flash-info"
    Success -> "flash-success"
    Warning -> "flash-warning"
    Error -> "flash-error"
  }
}
