import { ClientHook } from "sprocket-js";

export const FormControl: ClientHook = {
  create({ el, handleEvent }) {
    const form = el as HTMLFormElement;

    handleEvent("submit", () => {
      form.submit();
    });

    handleEvent("reset", () => {
      form.reset();
    });
  },
};
