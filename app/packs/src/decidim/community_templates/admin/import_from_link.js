/**
 * Hook the close button to remove the anchor from the url.
 */
document.addEventListener('decidim:loaded', function() {
  if(window.Decidim.currentDialogs["template-direct-link-modal"]) {
    const originalClose = window.Decidim.currentDialogs["template-direct-link-modal"].close;
    window.Decidim.currentDialogs["template-direct-link-modal"].close = function() {
      originalClose();
      window.location.hash = "";
      window.location.reload();
    };
  }
});
/**
 * Check if the anchor is #js-import-from-link and open the modal.
 * (if you reload the page while the modal is open, the modal will keep in open state)
 */
window.addEventListener('DOMContentLoaded', function() {
  if(this.window.location.hash === '#js-import-from-link') {
    if(window.Decidim.currentDialogs) {
      window.Decidim.currentDialogs["template-direct-link-modal"].open();
    } else {
      document.addEventListener('decidim:loaded', function() {
        window.Decidim.currentDialogs["template-direct-link-modal"].open();
      });
    }
  }
});
/**
 * Listen to anchor changes. If the anchor is #js-import-from-link, open the modal.
 */
window.addEventListener('popstate', function(event) {
  if (window.location.hash === '#js-import-from-link') {
    if(window.Decidim.currentDialogs) {
      window.Decidim.currentDialogs["template-direct-link-modal"].open();
    } else {
      document.addEventListener('decidim:loaded', function() {
        window.Decidim.currentDialogs["template-direct-link-modal"].open();
      });
    }
  }
});