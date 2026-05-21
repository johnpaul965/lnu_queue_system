#!/bin/bash
set -e

export PATH="$PATH":"$HOME/.pub-cache/bin"

echo "Generating .env from environment variables..."
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

echo "Building Flutter web app..."
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo "Replacing service worker with cache-clearing kill switch..."
cat > build/web/flutter_service_worker.js << 'SWEOF'
// Kill-switch service worker: clears all caches and unregisters itself
self.addEventListener('install', function(e) {
  self.skipWaiting();
});
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(keys.map(function(k) { return caches.delete(k); }));
    }).then(function() {
      return self.clients.claim();
    }).then(function() {
      return registration.unregister();
    })
  );
});
SWEOF

echo "Disabling service worker registration in bootstrap..."
perl -i -0pe 's/_flutter\.loader\.load\(\{.*?\}\);/_flutter.loader.load({});/s' build/web/flutter_bootstrap.js

echo "Injecting unregister script into index.html..."
perl -i -pe 's|<head>|<head><script>if("serviceWorker"in navigator){navigator.serviceWorker.getRegistrations().then(function(r){r.forEach(function(sw){sw.unregister();});});}</script>|' build/web/index.html

echo "Installing dhttpd..."
dart pub global activate dhttpd

echo "Serving Flutter web app on port 5000..."
dhttpd --path build/web --port 5000
