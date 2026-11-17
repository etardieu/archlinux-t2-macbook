#!/usr/bin/env bash
# Phase 1 pre-flight: build the KAIT2EN DKMS module set against Arch's stock
# kernel inside a throwaway archlinux container. It does not touch target
# partitions; the report is written into the mounted project directory.
set -u
export LC_ALL=C

REPO=${REPO:-/src/KaiT2en-Fedora}
UPSTREAM=https://github.com/kaiT2en/KaiT2en-Fedora
KAIT2EN_BRANCH=${KAIT2EN_BRANCH:-main}
REPORT=${REPORT:-/work/phase1-report.txt}
declare -a RESULTS=()

log() { printf '\n=== %s\n' "$*"; }

ensure_upstream() {
	# A prepared tree (e.g. the branch archive shipped in the live image)
	# needs no network and has no git metadata.
	if [[ ! -d "$REPO/.git" && -d "$REPO/modules" ]]; then
		echo "using existing source tree (no git metadata): $REPO"
		return 0
	fi
	mkdir -p "$REPO"
	[[ -d "$REPO/.git" ]] || git init -q "$REPO"
	git -C "$REPO" remote get-url origin >/dev/null 2>&1 ||
		git -C "$REPO" remote add origin "$UPSTREAM"
	git -C "$REPO" fetch --depth 1 origin "$KAIT2EN_BRANCH"
	git -C "$REPO" checkout -q FETCH_HEAD
	git -C "$REPO" config --global --add safe.directory "$REPO" 2>/dev/null || true
}

fail_count=0
ok_count=0

stage_module() {
	local name=$1 src dst version
	src="$REPO/modules/$name"
	[[ "$name" == "linux-apfs-rw" ]] && src="$REPO/third-party/linux-apfs-rw"
	[[ -f "$src/dkms.conf" ]] || { echo "missing $src/dkms.conf"; return 1; }
	version="$(sed -n 's/^PACKAGE_VERSION="\([^"]*\)".*/\1/p' "$src/dkms.conf")"
	[[ -n "$version" ]] || { echo "no PACKAGE_VERSION in $src/dkms.conf"; return 1; }
	dst="/usr/src/$name-$version"
	rm -rf "$dst"
	mkdir -p "$dst"
	tar -C "$src" \
		--exclude='.git' --exclude='*.ko' --exclude='*.o' --exclude='*.mod' \
		--exclude='*.mod.c' --exclude='.*.cmd' --exclude='Module.symvers' \
		--exclude='modules.order' -cf - . | tar -C "$dst" -xf -
	if [[ "$name" == "apple-t2-bridge" ]]; then
		local component
		for component in t2-ave t2-sidecar; do
			mkdir -p "$dst/$component"
			tar -C "$REPO/t2-services/t2-ave/kernel/$component" \
				--exclude='.git' --exclude='*.ko' --exclude='*.o' \
				--exclude='*.mod' --exclude='*.mod.c' --exclude='.*.cmd' \
				--exclude='Module.symvers' --exclude='modules.order' \
				-cf - . | tar -C "$dst/$component" -xf -
		done
	fi
	MODULE_VERSION="$version"
}

build_module() {
	local name=$1 version
	MODULE_VERSION=
	if ! stage_module "$name"; then
		echo "STAGING FAILED: $name"
		RESULTS+=("FAIL  $name (staging)")
		fail_count=$((fail_count + 1))
		return 1
	fi
	version="$MODULE_VERSION"
	log "BUILD $name/$version"
	if dkms add -m "$name" -v "$version" >/dev/null 2>&1 ||
		dkms status -m "$name" -v "$version" >/dev/null 2>&1; then
		if dkms build --force -m "$name" -v "$version" -k "$KVER" &&
			dkms install --no-depmod --force -m "$name" -v "$version" -k "$KVER"; then
			echo "BUILD+INSTALL OK: $name/$version"
			RESULTS+=("OK    $name/$version")
			ok_count=$((ok_count + 1))
			return 0
		fi
	fi
	echo "BUILD OR INSTALL FAILED: $name/$version"
	RESULTS+=("FAIL  $name/$version")
	fail_count=$((fail_count + 1))
	return 1
}

set -o pipefail
{
	log "container baseline"
	cat /etc/os-release | head -2
	uname -r

	if [[ ${PACKAGE_UPGRADE:-1} == 1 ]]; then
		log "pacman -Syu"
		pacman -Syu --noconfirm || { echo "FATAL: pacman -Syu failed"; exit 1; }
	else
		log "pacman -Syu (skipped: PACKAGE_UPGRADE=0)"
	fi

	if [[ ${INSTALL_PACKAGES:-1} == 1 ]]; then
		log "install toolchain and Arch kernel headers"
		pacman -S --noconfirm --needed base-devel linux linux-headers dkms git bc ||
			{ echo "FATAL: package install failed"; exit 1; }
	else
		log "package install (skipped: INSTALL_PACKAGES=0)"
	fi

	KVER="$(ls -1 /usr/lib/modules | sort -V | tail -1)"
	echo "target kernel: $KVER"
	modinfo -n "$KVER" >/dev/null 2>&1 || true
	ls -l "/usr/lib/modules/$KVER/build" || true
	dkms --version

	log "fetch KAIT2EN branch $KAIT2EN_BRANCH"
	if ! ensure_upstream; then
		echo "FATAL: could not fetch $UPSTREAM branch $KAIT2EN_BRANCH"
		exit 1
	fi
	if [[ -d "$REPO/.git" ]]; then
		echo "KAIT2EN branch: $KAIT2EN_BRANCH"
	else
		echo "KAIT2EN source: $REPO (pre-extracted)"
	fi

	log "state before any KAIT2EN module"
	dkms status || true

	for m in apple-t2-bridge t2smc t2smp t2sbs t2bdrm t2touchbar \
		hid_t2magicmouse t2_precision_trackpad t2_trackpad_actuator \
		t2mfi_fastcharge t2gmux linux-apfs-rw; do
		build_module "$m" || true
	done

	log "dkms status"
	dkms status || true

	log "installed modules under /updates"
	find "/usr/lib/modules/$KVER/updates" -name '*.ko*' 2>/dev/null | sort || true

	log "vermagic of installed modules"
	for ko in $(find "/usr/lib/modules/$KVER/updates" -name '*.ko*' 2>/dev/null | sort); do
		printf '%-28s %s\n' "$(basename "$ko")" "$(modinfo -F vermagic "$ko" 2>/dev/null)"
	done

	log "depmod smoke test"
	depmod -a "$KVER" && echo "depmod OK"

	log "SUMMARY"
	printf '%s\n' "${RESULTS[@]}"
	echo "built: $ok_count  failed: $fail_count  kernel: $KVER"
	# exit from inside the subshell so the status survives the pipe
	exit "$fail_count"
} 2>&1 | tee "$REPORT"
