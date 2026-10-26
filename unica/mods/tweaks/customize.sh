# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch" &> /dev/null || true

# Disable FM Radio country restrictions
if [[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_CHIP_VENDOR")" != "0" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FMRADIO_CONFIG_AVOID_REGION" --delete

    SMALI_PATCH "system" "system/framework/samsungfmradiolib.jar" \
        "smali/com/samsung/frameworks/fmradio/FMRadioImpl.smali" "return" \
        'isRadioNotSupportedInRegion()Z' \
        'false'
fi

SHADE_WINDOW_BLUR_PCT=100
SHADE_CONTENT_BLUR_PCT=200

DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

SYSTEMUI_RES="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/res"

for ENTRY in "max_shade_window_blur_radius:$SHADE_WINDOW_BLUR_PCT" \
        "max_shade_content_blur_radius:$SHADE_CONTENT_BLUR_PCT"; do
    DIMEN_NAME="${ENTRY%%:*}"
    DIMEN_PCT="${ENTRY##*:}"

    if [[ "$DIMEN_PCT" == "100" ]]; then
        continue
    fi

    DIMEN_FILES="$(find "$SYSTEMUI_RES" -path "*/values*/*.xml" ! -name "public.xml" \
        -exec grep -l "name=\"$DIMEN_NAME\"" {} + 2> /dev/null || true)"

    if [ -z "$DIMEN_FILES" ]; then
        LOGW "Dimen \"$DIMEN_NAME\" not found in SystemUI.apk, skipping"
        continue
    fi

    while IFS= read -r f; do
        DIMEN_FILE="${f#"$SYSTEMUI_RES"/}"

        DIMEN_ORIG="$(grep -hoE "name=\"$DIMEN_NAME\">[^<]*<" "$f" 2> /dev/null | head -n 1 \
            | sed -e 's/^[^>]*>//' -e 's/<$//' || true)"
        DIMEN_VALUE="$DIMEN_ORIG"

        DIMEN_DEPTH=0
        while [[ "$DIMEN_VALUE" == "@dimen/"* ]] && [ "$DIMEN_DEPTH" -lt 5 ]; do
            DIMEN_REF="${DIMEN_VALUE#@dimen/}"
            DIMEN_VALUE="$(find "$SYSTEMUI_RES" -path "*/values/*.xml" ! -name "public.xml" \
                -exec grep -hoE "name=\"$DIMEN_REF\">[^<]*<" {} + 2> /dev/null | head -n 1 \
                | sed -e 's/^[^>]*>//' -e 's/<$//' || true)"
            DIMEN_DEPTH=$((DIMEN_DEPTH + 1))
        done

        if [[ ! "$DIMEN_VALUE" =~ ^(-?[0-9]*\.?[0-9]+)([a-zA-Z]*)$ ]]; then
            LOGW "\"$DIMEN_NAME\" in \"$DIMEN_FILE\" is \"$DIMEN_ORIG\" and cannot be resolved to a number, left untouched"
            continue
        fi

        DIMEN_NEW="$(awk -v v="${BASH_REMATCH[1]}" -v p="$DIMEN_PCT" -v u="${BASH_REMATCH[2]}" \
            'BEGIN { printf "%.1f%s", v * p / 100, u }')"

        LOG "- Scaling \"$DIMEN_NAME\" in \"$DIMEN_FILE\": $DIMEN_ORIG -> $DIMEN_NEW ($DIMEN_PCT%)"
        awk -v NAME="$DIMEN_NAME" -v NEW="$DIMEN_NEW" '
            index($0, "name=\"" NAME "\"") && match($0, />[^<]*</) {
                sub(/>[^<]*</, ">" NEW "<")
            }
            { print }
        ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done <<< "$DIMEN_FILES"
done

unset SHADE_WINDOW_BLUR_PCT SHADE_CONTENT_BLUR_PCT SYSTEMUI_RES ENTRY DIMEN_NAME DIMEN_PCT DIMEN_FILES \
    DIMEN_FILE DIMEN_ORIG DIMEN_VALUE DIMEN_DEPTH DIMEN_REF DIMEN_NEW

CHIP_IDS="ongoing_call_chip samsung_ongoing_cast_chip ongoing_activity_capsule sec_media_capsule"

DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

CHIP_RES="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/res"

for CHIP_ID in $CHIP_IDS; do
    CHIP_FILES="$(grep -rlE "android:id=\"@\+?id/$CHIP_ID\"" "$CHIP_RES" --include=*.xml 2> /dev/null | grep "/layout" || true)"

    if [ -z "$CHIP_FILES" ]; then
        LOGW "View \"$CHIP_ID\" not found in SystemUI layouts, skipping"
        continue
    fi

    while IFS= read -r f; do
        LOG "- Hiding \"$CHIP_ID\" in \"${f#"$CHIP_RES"/}\""
        CHIP_ID="$CHIP_ID" perl -0pi -e '
            my $id = $ENV{CHIP_ID};
            s{(<[A-Za-z0-9_.]+\s[^<>]*?android:id="\@\+?id/\Q$id\E"[^<>]*>)}{
                my $t = $1;
                $t =~ s/android:layout_width="[^"]*"/android:layout_width="0.0dip"/;
                $t =~ s/android:layout_height="[^"]*"/android:layout_height="0.0dip"/;
                $t =~ s/android:visibility="[^"]*"/android:visibility="gone"/;
                $t
            }gse
        ' "$f"
    done <<< "$CHIP_FILES"
done

unset CHIP_IDS CHIP_RES CHIP_ID CHIP_FILES

HIDE_STOCK_HEADS_UP=true

if $HIDE_STOCK_HEADS_UP; then
    SYSTEMUI_DIR="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk"

    HU_FILE="$(find "$SYSTEMUI_DIR" -type f \
        -path '*/statusbar/notification/interruption/NotificationInterruptStateProviderImpl.smali' \
        | head -n 1 || true)"

    if [ -z "$HU_FILE" ]; then
        LOGW "NotificationInterruptStateProviderImpl not found in SystemUI, stock heads-up left alone"
    else
        LOG "- Disabling stock heads-up in \"${HU_FILE#"$SYSTEMUI_DIR"/}\""
        perl -0pi -e '
            s{(\.method [^\n]*? (?:checkHeadsUp|shouldHeadsUpWhenAwake)\([^\n]*\)Z\n).*?(\.end method)}{$1    .locals 1\n\n    const/4 v0, 0x0\n\n    return v0\n$2}gs
        ' "$HU_FILE"
        if ! grep -A4 -E '^\.method .* (checkHeadsUp|shouldHeadsUpWhenAwake)\(' "$HU_FILE" | grep -q "const/4 v0, 0x0"; then
            LOGW "heads-up methods not patched, stock heads-up left alone"
        fi
    fi

    unset SYSTEMUI_DIR HU_FILE
fi
unset HIDE_STOCK_HEADS_UP

ZEST_SYSUI_BOOT=false

if $ZEST_SYSUI_BOOT; then
    SYSTEMUI_DIR="$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk"

    ZB_APP="$(find "$SYSTEMUI_DIR" -type f -path '*/com/android/systemui/SystemUIApplication.smali' | head -n 1 || true)"

    if [ -z "$ZB_APP" ]; then
        LOGW "SystemUIApplication.smali not found, Zest Island will not start inside SystemUI"
    elif grep -q "ZestBoot" "$ZB_APP"; then
        LOG "- ZestBoot already present in SystemUIApplication, skipping"
    else
        LOG "- Hooking ZestBoot into \"${ZB_APP#"$SYSTEMUI_DIR"/}\""
        perl -0pi -e '
            s|(\.method [a-z ]*onCreate\(\)V.*?invoke-super \{p0\}, L[^;]+;->onCreate\(\)V\n)|$1\n    invoke-static {p0}, Lcom/android/systemui/ZestBoot;->start(Landroid/content/Context;)V\n|s
        ' "$ZB_APP"

        if ! grep -q "ZestBoot" "$ZB_APP"; then
            LOGW "onCreate() of SystemUIApplication not matched, Zest Island will not start inside SystemUI"
        else
            cat > "$(dirname "$ZB_APP")/ZestBoot.smali" << 'SMALI'
.class public final Lcom/android/systemui/ZestBoot;
.super Ljava/lang/Object;

.field private static started:Z

.method public static start(Landroid/content/Context;)V
    .locals 6

    sget-boolean v0, Lcom/android/systemui/ZestBoot;->started:Z

    if-eqz v0, :cond_go

    return-void

    :cond_go
    const/4 v0, 0x1

    sput-boolean v0, Lcom/android/systemui/ZestBoot;->started:Z

    :try_start_0
    new-instance v0, Ldalvik/system/PathClassLoader;

    const-string v1, "/system/priv-app/ZestIsland/ZestIsland.apk"

    invoke-virtual {p0}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v2

    invoke-direct {v0, v1, v2}, Ldalvik/system/PathClassLoader;-><init>(Ljava/lang/String;Ljava/lang/ClassLoader;)V

    const-string v1, "dev.zest.island.sysui.Boot"

    invoke-virtual {v0, v1}, Ljava/lang/ClassLoader;->loadClass(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const/4 v2, 0x1

    new-array v3, v2, [Ljava/lang/Class;

    const/4 v4, 0x0

    const-class v5, Landroid/content/Context;

    aput-object v5, v3, v4

    const-string v1, "start"

    invoke-virtual {v0, v1, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v1

    new-array v3, v2, [Ljava/lang/Object;

    aput-object p0, v3, v4

    const/4 v2, 0x0

    invoke-virtual {v1, v2, v3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :catchall_0
    return-void
.end method
SMALI
        fi
    fi

    unset SYSTEMUI_DIR ZB_APP
fi
unset ZEST_SYSUI_BOOT