import { ClientHook } from "sprocket-js";

export const Focuser: ClientHook = {
  create({ el, handleEvent }) {
    const input = el as HTMLInputElement;

    handleEvent("focus", () => {
      setTimeout(() => {
        input.focus();
        input.setSelectionRange(input.value.length, input.value.length);
      }, 10);
    });
  },
};
