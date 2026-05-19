{{flutter_js}}
{{flutter_build_config}}

// Load CanvasKit from the app bundle (not gstatic CDN) — required offline / restricted networks.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: '/canvaskit/',
  },
});
