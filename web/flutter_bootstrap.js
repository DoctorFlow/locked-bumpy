{{flutter_js}}
{{flutter_build_config}}

const opening = document.getElementById("opening");
const status = document.getElementById("opening-status");
const retry = document.getElementById("opening-retry");

function showRetry(message) {
  if (opening.isConnected) {
    status.textContent = message;
    retry.hidden = false;
  }
}

const slowStart = window.setTimeout(
  () => showRetry("Little Bumpy is taking a little longer to open."),
  15000,
);
window.addEventListener("flutter-first-frame", () => {
  window.clearTimeout(slowStart);
  opening.remove();
}, { once: true });

function openingFailed() {
  window.clearTimeout(slowStart);
  showRetry("Little Bumpy couldn’t open.");
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL("canvaskit/", document.baseURI).href,
    fontFallbackBaseUrl: new URL("fonts/", document.baseURI).href,
  },
  onEntrypointLoaded: async (initializer) => {
    try {
      const runner = await initializer.initializeEngine();
      await runner.runApp();
    } catch (_) {
      openingFailed();
    }
  },
}).catch(openingFailed);
