#!/usr/bin/env bash
set -euo pipefail

install_packages=false

usage() {
  cat <<'EOF'
Usage:
  dolphin-document-preview.sh [--install]

Default mode checks Dolphin/KIO preview support and writes user-level preview
settings. With --install it also installs the Dolphin thumbnailer packages via
sudo. It does not install external document editors/viewers.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --install)
      install_packages=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

has_package() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

check_package() {
  local package="$1"
  if has_package "$package"; then
    log "OK package: $package"
  else
    log "Missing package: $package"
  fi
}

check_plugin_mime() {
  local plugin="$1"
  local pattern="$2"
  if [[ ! -f "$plugin" ]]; then
    log "Missing plugin: $plugin"
    return 1
  fi

  if strings "$plugin" | grep -Eiq "$pattern"; then
    log "OK plugin MIME: $(basename "$plugin") matches /$pattern/"
  else
    log "Plugin present but MIME not found: $(basename "$plugin") /$pattern/"
    return 1
  fi
}

join_by_comma() {
  local IFS=,
  printf '%s' "$*"
}

installed_preview_plugins() {
  local plugin_dir="/usr/lib/x86_64-linux-gnu/qt5/plugins/kf5/thumbcreator"
  local plugins=()
  local plugin

  if [[ -d "$plugin_dir" ]]; then
    while IFS= read -r plugin; do
      plugins+=("$plugin")
    done < <(find "$plugin_dir" -maxdepth 1 -type f -name '*.so' -printf '%f\n' | sed 's/\.so$//' | sort)
  fi

  if [[ -f /usr/share/kservices5/directorythumbnail.desktop ]]; then
    plugins+=(directorythumbnail)
  fi

  join_by_comma "${plugins[@]}"
}

check_enabled_plugin() {
  local enabled_plugins="$1"
  local plugin="$2"

  if [[ ",$enabled_plugins," == *",$plugin,"* ]]; then
    log "OK enabled preview plugin: $plugin"
  else
    log "Missing enabled preview plugin: $plugin"
  fi
}

write_dolphin_config() {
  local global_view_dir="$HOME/.local/share/dolphin/view_properties/global"
  local global_view_file="$global_view_dir/.directory"
  local enabled_plugins

  mkdir -p "$global_view_dir"
  enabled_plugins="$(installed_preview_plugins)"

  if command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file dolphinrc --group PreviewSettings --key MaximumSize 104857600
    kwriteconfig5 --file dolphinrc --group PreviewSettings --key MaximumRemoteSize 10485760
    kwriteconfig5 --file dolphinrc --group PreviewSettings --key Plugins "$enabled_plugins"
    kwriteconfig5 --file dolphinrc --group InformationPanel --key showPreview true
    kwriteconfig5 --file baloofileinformationrc --group InformationPanel --key showPreview true
    kwriteconfig5 --file "$global_view_file" --group Dolphin --key PreviewsShown true
  else
    log "Missing kwriteconfig5; cannot write KDE config automatically."
    return 1
  fi

  log "Wrote Dolphin preview settings:"
  log "  ~/.config/dolphinrc PreviewSettings MaximumSize=104857600 MaximumRemoteSize=10485760"
  log "  ~/.config/dolphinrc PreviewSettings Plugins=$enabled_plugins"
  log "  $global_view_file Dolphin PreviewsShown=true"
}

install_recommended_packages() {
  local packages=(
    dolphin
    kio-extras
    kdegraphics-thumbnailers
    ffmpegthumbs
  )

  log "Installing Dolphin thumbnailer packages: ${packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

main() {
  if "$install_packages"; then
    install_recommended_packages
  fi

  log "Dolphin version:"
  if command -v dolphin >/dev/null 2>&1; then
    dolphin --version || true
  else
    log "Missing command: dolphin"
  fi

  log "Checking packages"
  check_package dolphin
  check_package kio-extras
  check_package kdegraphics-thumbnailers
  check_package ffmpegthumbs

  log "Checking optional external viewers/editors"
  check_package okular
  check_package libreoffice-writer
  check_package libreoffice-calc
  check_package markdownpart

  log "Checking thumbnailer MIME declarations"
  check_plugin_mime /usr/lib/x86_64-linux-gnu/qt5/plugins/kf5/thumbcreator/gsthumbnail.so 'application/pdf' || true
  check_plugin_mime /usr/lib/x86_64-linux-gnu/qt5/plugins/kf5/thumbcreator/opendocumentthumbnail.so 'wordprocessingml\.document|spreadsheetml\.sheet' || true
  check_plugin_mime /usr/lib/x86_64-linux-gnu/qt5/plugins/kf5/thumbcreator/textthumbnail.so 'text/plain' || true
  check_plugin_mime /usr/lib/x86_64-linux-gnu/qt5/plugins/kf5/thumbcreator/textthumbnail.so 'text/markdown' || true

  log "Checking Markdown MIME"
  if command -v xdg-mime >/dev/null 2>&1; then
    printf 'README.md: '
    xdg-mime query filetype README.md 2>/dev/null || true
  fi

  write_dolphin_config

  log "Checking enabled preview plugins"
  if command -v kreadconfig5 >/dev/null 2>&1; then
    enabled_plugins="$(kreadconfig5 --file dolphinrc --group PreviewSettings --key Plugins 2>/dev/null || true)"
    check_enabled_plugin "$enabled_plugins" gsthumbnail
    check_enabled_plugin "$enabled_plugins" opendocumentthumbnail
    check_enabled_plugin "$enabled_plugins" textthumbnail
  fi

  if ! "$install_packages"; then
    log "Package install skipped. Re-run with --install if Dolphin thumbnailer packages are missing."
  fi

  log "Done. Restart Dolphin to pick up all settings."
}

main "$@"
