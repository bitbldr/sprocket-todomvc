import { DoubleClick } from "./hooks/doubleclick";
import { FormControl } from "./hooks/formControl";
import { Focuser } from "./hooks/focuser";
import { connect } from "sprocket-js";

const hooks = {
  DoubleClick,
  FormControl,
  Focuser,
};

window.addEventListener("DOMContentLoaded", () => {
  const csrfToken = document
    .querySelector("meta[name=csrf-token]")
    ?.getAttribute("content");

  if (csrfToken) {
    let connectPath =
      window.location.pathname === "/"
        ? "/connect"
        : window.location.pathname.split("/").concat("connect").join("/");

    connect(connectPath, {
      csrfToken,
      targetEl: document.querySelector("#app") as Element,
      hooks,
    });
  } else {
    console.error("Missing CSRF token");
  }
});
