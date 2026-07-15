#!/usr/bin/env bash
# Chẩn đoán + chạy Flutter trên iPhone (USB hoặc Wi‑Fi).
#
# Lỗi "Flutter could not access the local network" (port 5353) trên macOS:
#   → Terminal tích hợp Cursor thường KHÔNG có quyền Local Network.
#   → Chạy: ./scripts/ios_wireless_dev.sh install   (cài app, mở tay trên iPhone)
#   → Hoặc mở Terminal.app (ngoài Cursor) rồi: ./scripts/ios_wireless_dev.sh run
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE_NAME="${FLUTTER_DEVICE_NAME:-HuuNghia}"
DEVICE_ID="${FLUTTER_DEVICE_ID:-00008150-000924CE0A50C01C}"
MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
API_URL="${API_BASE_URL:-${MAC_IP:+http://${MAC_IP}:8080}}"

open_local_network_settings() {
  open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?LocalNetwork" 2>/dev/null \
    || open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork" 2>/dev/null \
    || true
}

cleanup_stale_pairings() {
  while IFS= read -r line; do
    id="$(echo "$line" | awk '{print $3}')"
    [[ -n "$id" && "$id" != "Identifier" ]] || continue
    state="$(echo "$line" | awk '{print $4}')"
    if [[ "$state" == "unavailable" ]]; then
      echo "==> Gỡ pairing cũ unavailable: $id"
      xcrun devicectl manage unpair --device "$id" 2>/dev/null || true
    fi
  done < <(xcrun devicectl list devices 2>/dev/null | tail -n +4)
}

cmd="${1:-}"

case "$cmd" in
  install)
    cleanup_stale_pairings
    echo "==> Cài app lên iPhone (không cần quyền Local Network / hot reload)"
    flutter install -d "$DEVICE_ID"
    echo ""
    echo "✓ Đã cài. Mở app trên iPhone. (be-blog phải chạy trên Mac, cùng Wi‑Fi)"
    ;;
  run)
    cleanup_stale_pairings
    echo "==> Chạy từ Terminal.app (KHÔNG dùng terminal Cursor) để tránh lỗi port 5353."
    echo "    Mở: Applications → Terminal, rồi chạy lại lệnh này."
    if [[ -n "$API_URL" ]]; then
      flutter run -d "$DEVICE_ID" --dart-define=API_BASE_URL="$API_URL"
    else
      flutter run -d "$DEVICE_ID"
    fi
    ;;
  fix-permissions)
    echo "==> Mở System Settings → Local Network"
    open_local_network_settings
    echo ""
    echo "Bật ON cho: Terminal, Cursor (nếu có), Dart"
    echo "Sau đó: Cmd+Q thoát Cursor hoàn toàn → mở lại"
    echo ""
    echo "Nếu Cursor không có trong danh sách, chạy flutter từ Terminal.app:"
    echo "  cd \"$ROOT\" && ./scripts/ios_wireless_dev.sh run"
    echo ""
    echo "Hoặc reset quyền (sẽ hỏi lại lần sau):"
    echo "  tccutil reset LocalNetwork"
    ;;
  *)
    echo "==> Flutter devices"
    flutter devices --device-timeout 15 || true
    cleanup_stale_pairings
    echo ""
    echo "==> CoreDevice"
    xcrun devicectl list devices 2>/dev/null || true
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Lỗi port 5353 trong Cursor → dùng một trong các cách:"
    echo ""
    echo "  A) Cài app (không hot reload):"
    echo "       ./scripts/ios_wireless_dev.sh install"
    echo ""
    echo "  B) Debug + hot reload — chạy từ Terminal.app (ngoài Cursor):"
    echo "       ./scripts/ios_wireless_dev.sh run"
    echo ""
    echo "  C) Sửa quyền Mac:"
    echo "       ./scripts/ios_wireless_dev.sh fix-permissions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
esac
