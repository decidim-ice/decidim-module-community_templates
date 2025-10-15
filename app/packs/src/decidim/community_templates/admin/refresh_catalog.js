async function refreshCatalog(forceSync=false) {
  const url = new URL("/admin/community_templates/community_templates", window.location.origin);
  if (forceSync) {
    url.searchParams.set('force_sync', 'true');
  }
  
  const response = await fetch(url, {
    method: "GET",
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Content-Type': 'application/json'
    }
  })
  if(response.ok) {
    const data = await response.json();
    console.log("Catalog refreshed", data);
  } else {
    console.error("Failed to refresh catalog");
  }
}

document.addEventListener("DOMContentLoaded", () => {
  if(window.location.pathname.startsWith("/admin/community_templates")) {
    refreshCatalog(forceSync=false);
  }
});

document.addEventListener("remote-modal:loaded", () => {
  refreshCatalog(forceSync=true);
});