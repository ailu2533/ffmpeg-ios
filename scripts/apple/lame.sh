#!/bin/bash

cd "${LIB_NAME}" || return 1

# ALWAYS CLEAN THE PREVIOUS BUILD
make distclean 2>/dev/null 1>/dev/null

update_config_scripts() {
  local CONFIG_URL_BASE="https://git.savannah.gnu.org/cgit/config.git/plain"
  local FILES=(config.sub config.guess)
  local need_update=0

  if [[ "${FORCE_UPDATE_CONFIG:-0}" == "1" ]]; then
    echo "INFO: FORCE_UPDATE_CONFIG=1 -> will refresh config scripts" >&2
    need_update=1
  fi

  for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "INFO: $f missing -> will download" >&2
      need_update=1
    fi
  done

  if [[ $need_update -eq 0 ]]; then
    # Probe support for target triplet
    if ! sh ./config.sub arm64-ios-darwin >/dev/null 2>&1; then
      echo "INFO: Existing config.sub does not recognize arm64-ios-darwin -> will update" >&2
      need_update=1
    fi
  fi

  if [[ $need_update -eq 0 ]]; then
    echo "INFO: Existing config.sub/config.guess OK, skip download" >&2
    return 0
  fi

  echo "INFO: Updating config.sub & config.guess ..." >&2
  for f in "${FILES[@]}"; do
    if command -v curl >/dev/null 2>&1; then
      curl -fL --silent --show-error "${CONFIG_URL_BASE}/${f}" -o "${f}.tmp"
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "${f}.tmp" "${CONFIG_URL_BASE}/${f}"
    else
      echo "ERR: curl or wget required." >&2
      exit 1
    fi
    chmod +x "${f}.tmp"
    mv "${f}.tmp" "${f}"
  done
}

update_config_scripts

# REGENERATE BUILD FILES IF NECESSARY OR REQUESTED
if [[ ! -f "${BASEDIR}"/src/"${LIB_NAME}"/configure ]] || [[ ${RECONF_lame} -eq 1 ]]; then
  autoreconf_library "${LIB_NAME}" 1>>"${BASEDIR}"/build.log 2>&1 || return 1
fi

./configure \
  --prefix="${LIB_INSTALL_PREFIX}" \
  --with-pic \
  --with-sysroot="${SDK_PATH}" \
  --with-libiconv-prefix="${SDK_PATH}"/usr \
  --enable-static \
  --disable-shared \
  --disable-fast-install \
  --disable-maintainer-mode \
  --disable-frontend \
  --disable-efence \
  --disable-gtktest \
  --host="${HOST}" || return 1

make -j$(get_cpu_count) || return 1

make install || return 1

# CREATE PACKAGE CONFIG MANUALLY
create_libmp3lame_package_config "3.100" || return 1
