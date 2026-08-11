#!/usr/bin/env bash
# verify_assets.sh — CYBERPUN-16-1-t2 asset-catalog contract check.
#
# v1 of this game shipped an EMPTY asset catalog with a green test suite
# (docs/bootstrap.md → "Key contracts to establish first" #1). A compiling
# catalog proves nothing on its own, so this script checks the three things a
# green build does not:
#
#   1. structural — every imageset names a BARE file that actually exists
#      inside that imageset, and no stray file lives inside the catalog.
#      Runs anywhere (no Xcode needed).
#   2. measurement — sweeps the committed PNGs with `sips` and reconciles them
#      against docs/asset_manifest.json, so slicing math has a MEASURED source
#      instead of ticket prose. Needs macOS.
#   3. build proof — compiles the catalog with `actool` and asserts every id in
#      the manifest is really present in the built Assets.car via `assetutil`.
#      Needs Xcode.
#
# Steps 2 and 3 are skipped (loudly) where the tool is unavailable; step 1
# always runs. Usage: `bash ./verify_assets.sh`
set -uo pipefail

CATALOG="CyberpunkMonsterCrawl/Assets.xcassets"
MANIFEST="docs/asset_manifest.json"
fail=0

err()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }
ok()   { printf '  ok   %s\n' "$1"; }
skip() { printf '  \033[33mSKIP\033[0m %s\n' "$1"; }

[ -d "$CATALOG" ]  || { echo "no catalog at $CATALOG"; exit 2; }
[ -f "$MANIFEST" ] || { echo "no manifest at $MANIFEST"; exit 2; }

# ---------------------------------------------------------------- 1. structure
echo "== 1. imageset references (bare filename, resolves inside the imageset) =="
imageset_count=0
while IFS= read -r contents; do
    dir=$(dirname "$contents")
    imageset_count=$((imageset_count + 1))
    names=$(grep -o '"filename"[[:space:]]*:[[:space:]]*"[^"]*"' "$contents" \
            | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
    if [ -z "$names" ]; then
        err "$dir declares no filename — it would compile to an EMPTY imageset"
        continue
    fi
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        case "$name" in
            */*) err "$dir filename '$name' is a path. actool documents \`filename\` as a bare name inside the .imageset; a '../' traversal is undefined and can silently yield an empty imageset." ;;
            *)   if [ -f "$dir/$name" ]; then
                     ok "$(basename "$dir") -> $name"
                 else
                     err "$dir references '$name', which does not exist in that folder"
                 fi ;;
        esac
    done <<EOF
$names
EOF
done < <(find "$CATALOG" -name Contents.json -path '*.imageset/*' | sort)
echo "  ($imageset_count imagesets checked)"

echo "== 2. no unassigned content inside the catalog =="
loose=$(find "$CATALOG" -type f ! -name Contents.json \
        ! -path '*.imageset/*' ! -path '*.appiconset/*' | sort)
if [ -n "$loose" ]; then
    while IFS= read -r f; do
        err "$f is inside the catalog but belongs to no imageset — actool recurses into unrecognised folders and warns on (or skips) unassigned content"
    done <<EOF
$loose
EOF
else
    ok "no loose files under $CATALOG"
fi

echo "== 3. group folders declare their namespacing explicitly =="
for group in Sprites Buildings; do
    gc="$CATALOG/$group/Contents.json"
    if [ ! -f "$gc" ]; then
        err "$gc missing — a group folder's namespacing would be implicit, and a later 'provides-namespace: true' would silently rename every id to $group/<id>"
    elif grep -q 'provides-namespace' "$gc"; then
        ok "$group/Contents.json pins provides-namespace"
    else
        err "$gc does not state provides-namespace explicitly"
    fi
done

# ------------------------------------------------------------- manifest fields
# One asset per line in the manifest keeps this parseable without a JSON tool.
field() { # field <line> <key>
    printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([^,}]*\).*/\1/p" \
        | tr -d ' "'
}

ids=$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST" \
      | sed 's/.*"\([^"]*\)"$/\1/')

echo "== 4. manifest covers exactly the committed imagesets =="
for id in $ids; do
    line=$(grep "\"id\"[[:space:]]*:[[:space:]]*\"$id\"" "$MANIFEST")
    file=$(field "$line" file)
    if [ -f "$file" ]; then ok "$id -> $file"; else err "manifest lists $id but $file is not committed"; fi
done
while IFS= read -r png; do
    id=$(basename "$png" .png)
    grep -q "\"id\"[[:space:]]*:[[:space:]]*\"$id\"" "$MANIFEST" \
        || err "$png is committed but absent from $MANIFEST — every committed byte must have a recorded measurement"
done < <(find "$CATALOG/Sprites" "$CATALOG/Buildings" -name '*.png' | sort)

# ----------------------------------------------------------- 5. sips measuring
echo "== 5. measured dimensions vs $MANIFEST =="
if ! command -v sips >/dev/null 2>&1; then
    skip "sips unavailable (not macOS) — dimensions in $MANIFEST stay PENDING-MEASUREMENT. Re-run this script on a macOS checkout before any consumer uses a number from the manifest."
else
    for id in $ids; do
        line=$(grep "\"id\"[[:space:]]*:[[:space:]]*\"$id\"" "$MANIFEST")
        file=$(field "$line" file)
        [ -f "$file" ] || continue
        mw=$(sips -g pixelWidth  "$file" | awk '/pixelWidth/  {print $2}')
        mh=$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')
        dw=$(field "$line" pixel_width)
        dh=$(field "$line" pixel_height)
        cw=$(field "$line" cell_width)
        ch=$(field "$line" cell_height)
        if [ "$dw" = "null" ] || [ "$dh" = "null" ]; then
            err "$id is unmeasured in the manifest. MEASURED NOW: ${mw}x${mh} — record it (and its cell grid) in $MANIFEST, provenance 'measured'."
            continue
        fi
        if [ "$dw" != "$mw" ] || [ "$dh" != "$mh" ]; then
            err "$id manifest says ${dw}x${dh} but the committed PNG measures ${mw}x${mh}"
            continue
        fi
        ok "$id measures ${mw}x${mh} as recorded"
        if [ "$cw" != "null" ] && [ "$ch" != "null" ]; then
            if [ $((mw % cw)) -ne 0 ] || [ $((mh % ch)) -ne 0 ]; then
                err "$id cell ${cw}x${ch} does not divide evenly into ${mw}x${mh} — the grid is wrong"
            else
                cols=$(field "$line" columns); rows=$(field "$line" rows)
                [ "$cols" = "null" ] || [ "$cols" = "$((mw / cw))" ] \
                    || err "$id columns=$cols but measured sheet gives $((mw / cw))"
                [ "$rows" = "null" ] || [ "$rows" = "$((mh / ch))" ] \
                    || err "$id rows=$rows but measured sheet gives $((mh / ch))"
            fi
        fi
    done
fi

# --------------------------------------------------- 6. actool / assetutil proof
echo "== 6. ids present in the compiled Assets.car =="
if ! command -v xcrun >/dev/null 2>&1 || ! xcrun --find actool >/dev/null 2>&1; then
    skip "actool unavailable (no Xcode) — 'the catalog compiles' has NOT been shown to mean 'the art is in the binary'."
else
    out=$(mktemp -d)
    if xcrun actool "$CATALOG" --compile "$out" --platform iphoneos \
            --minimum-deployment-target 16.0 \
            --output-partial-info-plist "$out/partial.plist" \
            --errors --warnings --notices >"$out/actool.log" 2>&1; then
        if [ -f "$out/Assets.car" ]; then
            info=$(xcrun assetutil --info "$out/Assets.car" 2>/dev/null)
            for id in $ids; do
                printf '%s' "$info" | grep -q "\"Name\"[[:space:]]*:[[:space:]]*\"$id\"" \
                    && ok "$id is in Assets.car" \
                    || err "$id is NOT in the compiled Assets.car — the imageset compiled EMPTY"
            done
        else
            err "actool produced no Assets.car (see $out/actool.log)"
        fi
    else
        err "actool failed: $(tail -n 20 "$out/actool.log")"
    fi
    grep -q 'unassigned' "$out/actool.log" 2>/dev/null \
        && err "actool reported unassigned content inside the catalog (see $out/actool.log)"
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "asset contract OK (note any SKIPs above — a skipped check is not a pass)"
    exit 0
fi
echo "asset contract FAILED"
exit 1
