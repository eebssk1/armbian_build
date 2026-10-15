#!/usr/bin/env bash

set +x
set -euo pipefail
: "${IMAGE_PASSWORD:?IMAGE_PASSWORD is required}"
sevenzip=$(command -v 7zz || command -v 7z)
cd -- "${1:-output/images}"
shopt -s nullglob
images=(*.img)
if ((${#images[@]} == 0)); then
	printf '%s\n' 'No raw images found' >&2
	exit 1
fi

for image in "${images[@]}"; do
	archive="${image}.7z"
	if [[ -e "$archive" ]]; then
		printf '%s\n' 'Refusing to update an existing image archive' >&2
		exit 1
	fi
	if ! "$sevenzip" a -t7z -m0=lzma2 -mx=7 -mmt=2 -mhe=on "-p${IMAGE_PASSWORD}" "$archive" "./$image" ||
		! "$sevenzip" t "-p${IMAGE_PASSWORD}" "$archive"; then
		rm -f -- "$archive"
		exit 1
	fi
	sha256sum -- "$archive" > "${archive}.sha256"
	rm -- "$image"
done
