{{flutter_js}}
{{flutter_build_config}}

// No service worker: it kept serving an old build after every upload.
// The server sends no-cache headers instead (see web/.htaccess), so updates show on reload.
_flutter.loader.load();
