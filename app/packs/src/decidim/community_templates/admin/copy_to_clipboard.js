function mountCopyToClipboard() {
  const copyButtons = document.querySelectorAll("[data-clipboard-target]");
  if(!copyButtons.length) return;
  let timeout;
  copyButtons.forEach((button) => {
    if(button.getAttribute("data-clipboard-ready")) return;
    button.addEventListener("click", (e) => {
      e.preventDefault();
      const targetId = button.getAttribute("data-clipboard-target");
      const target = document.getElementById(targetId);
      if(!target) return;
      const promises = []
      // add to clipboard for recent browsers (wont'work in older broweser)
      promises.push(navigator.clipboard.writeText(target.textContent));
      Promise.all(promises).then(() => {
        if(timeout) clearTimeout(timeout);
        button.querySelector(".copy_success_message").removeAttribute("aria-hidden");
        timeout = setTimeout(() => {
          button.querySelector(".copy_success_message").setAttribute("aria-hidden", "true");
        }, 2000);
      });
      // add a data-clipboard-ready to avoid double mounting
      button.setAttribute("data-clipboard-ready", "true");
    });
  });
}
document.addEventListener("DOMContentLoaded", () => {
  mountCopyToClipboard();
});

document.addEventListener("remote-modal:loaded", () => {
  mountCopyToClipboard();
});