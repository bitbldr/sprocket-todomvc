import gleam/option.{None}
import sprocket/context.{type Element}
import sprocket/html/attributes.{
  charset, class, content, href, lang, name, rel, src,
}
import sprocket/html/elements.{body, head, html, link, meta, script, title}

pub fn page_layout(page_title: String, csrf: String) {
  fn(inner_content: Element) {
    html([lang("en")], [
      head([], [
        title(page_title),
        meta([charset("utf-8")]),
        meta([name("csrf-token"), content(csrf)]),
        meta([name("viewport"), content("width=device-width, initial-scale=1")]),
        meta([
          name("description"),
          content("An Example Sprocket Todo MVC Application"),
        ]),
        link([rel("stylesheet"), href("/main.css")]),
      ]),
      body(
        [
          class(
            "bg-white dark:bg-gray-900 dark:text-white flex flex-col h-screen",
          ),
        ],
        [inner_content, script([src("/app.js")], None)],
      ),
    ])
  }
}
