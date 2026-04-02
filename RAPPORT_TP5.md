# Rapport d'analyse — TP5 Reverse Engineering Android IoT
**Auteur :** user
**Date :** 02/04/2026 14:30
**Machine :** user — 6.8.0-106-generic
**Cible :** InjuredAndroid (Damn Vulnerable Android IoT App)
**Dossier :** /home/user/IoT/formation-Jour2/android-analysis

---
## 1. Outils installés

| Outil | Statut | Version |
|---|---|---|
| `jadx` | ✔ Présent | 1.4.7 |
| `frida` | ✔ Présent | 17.9.1 |
| `objection` | ✘ Absent | — |
| `adb` | ✔ Présent | Android Debug Bridge version 1.0.41 |
| `docker` | ✔ Présent | Docker version 28.2.2, build 28.2.2-0ubuntu1~24.04.1 |
| `frida-server` | ⚠ Absent | — |

## 2. APK InjuredAndroid

| Propriété | Valeur |
|---|---|
| Fichier | `InjuredAndroid.apk` |
| Taille | 24M |
| Type | Android package (APK), with AndroidManifest.xml |
| MD5 | `6744eaa4c0802c1086d1e8a38f58fe48` |
| SHA256 | `b6b8d2dbd7a428b7754e6e537ba5790c35a73253533454e0768dbf1520a7ed15` |

## 3. Décompilation JADX

- **Fichiers Java décompilés :** 2063
- **Packages identifiés :**
```
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources
c
c/b
c/a
c/a/c
c/a/c/c
c/a/c/b
c/a/c/a
c/a/d
com
```

## 4. Analyse AndroidManifest.xml

- **Package :** `b3nac.injuredandroid`
- **Version :** 1.0.9

### Activités exportées (vulnérabilité)

**7 activité(s) accessibles sans authentification :**
```
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_flag_eighteen" android:name="b3nac.injuredandroid.FlagEighteenActivity" android:exported="true"/>
        <activity android:name="b3nac.injuredandroid.SettingsActivity"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_exported_protected_intent" android:name="b3nac.injuredandroid.ExportedProtectedIntent" android:exported="true"/>
        <activity android:name="b3nac.injuredandroid.QXV0aA" android:exported="true"/>
        <activity android:name="b3nac.injuredandroid.XSSTextActivity"/>
        <activity android:name="b3nac.injuredandroid.DisplayPostXSS"/>
        <activity android:name="b3nac.injuredandroid.FlagOneSuccess"/>
        <activity android:name="b3nac.injuredandroid.b25lActivity" android:exported="true"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_flag_two" android:name="b3nac.injuredandroid.FlagTwoActivity"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_flag_three" android:name="b3nac.injuredandroid.FlagThreeActivity"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_flag_four" android:name="b3nac.injuredandroid.FlagFourActivity"/>
        <receiver android:name="b3nac.injuredandroid.FlagFiveReceiver" android:exported="true"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_flag_five" android:name="b3nac.injuredandroid.FlagFiveActivity"/>
        <activity android:theme="@style/AppTheme.NoActionBar" android:label="@string/title_activity_test_broadcast_reciever" android:name="b3nac.injuredandroid.TestBroadcastReceiver" android:exported="true"/>
        <activity android:name="b3nac.injuredandroid.ContactActivity"/>
        <activity android:theme="@android:style/Theme.Translucent.NoTitleBar" android:name="com.google.firebase.auth.internal.FederatedSignInActivity" android:permission="com.google.firebase.auth.api.gms.permission.LAUNCH_FEDERATED_SIGN_IN" android:exported="true" android:excludeFromRecents="true" android:launchMode="singleTask"/>
```

### Permissions déclarées (5)
```
android.permission.ACCESS_NETWORK_STATE
android.permission.INTERNET
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.READ_PHONE_STATE
android.permission.READ_EXTERNAL_STORAGE
```

**⚠ Permissions dangereuses :**
```
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.READ_PHONE_STATE
android.permission.READ_EXTERNAL_STORAGE
```

## 5. Secrets hardcodés

| Pattern | Fichiers | Criticité |
|---|---|---|
| `api_key` | 4 | **Critique** |
| `password` | 26 | **Critique** |
| `secret` | 24 | **Critique** |
| `token` | 40 | **Critique** |
| `firebase` | 363 | Elevée |
| `aws` | 4 | Elevée |
| `mqtt` | 0 | — |
| `broker` | 3 | Elevée |
| `private_key` | 3 | Elevée |
| `http://` | 3 | Elevée |

### Détail : `password`
```java
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/internal/m0.java:182:                if (str.equals("MISSING_PASSWORD")) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/internal/m0.java:238:                if (str.equals("WEAK_PASSWORD")) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/internal/m0.java:308:                if (str.equals("PASSWORD_LOGIN_DISABLED")) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/internal/m0.java:385:                if (str.equals("RESET_PASSWORD_EXCEED_LIMIT")) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/internal/m0.java:406:                if (str.equals("INVALID_PASSWORD")) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/c.java:20:            throw new IllegalArgumentException("Cannot create an EmailAuthCredential without a password or emailLink.");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/c.java:30:        return "password";
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/c.java:39:        return !TextUtils.isEmpty(this.g) ? "password" : "emailLink";
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/z/a/y.java:13:        com.google.android.gms.common.internal.r.g(str2, "password cannot be null or empty");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/z/a/y.java:42:        return "reauthenticateWithEmailPasswordWithData";
```

### Détail : `secret`
```java
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/EciesHkdfRecipientKem.java:14:        return Hkdf.computeEciesHkdfSymmetricKey(bArr, EllipticCurves.computeSharedSecret(this.recipientPrivateKey, EllipticCurves.getEcPublicKey(this.recipientPrivateKey.getParams(), pointFormatType, bArr)), str, bArr2, bArr3, i);
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:11:import javax.crypto.spec.SecretKeySpec;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:60:            SecretKeySpec secretKeySpec;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:65:                    secretKeySpec = new SecretKeySpec(new byte[this.mac.getMacLength()], HkdfStreamingPrf.getJavaxHmacName(HkdfStreamingPrf.this.hashType));
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:68:                    secretKeySpec = new SecretKeySpec(HkdfStreamingPrf.this.salt, HkdfStreamingPrf.getJavaxHmacName(HkdfStreamingPrf.this.hashType));
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:70:                mac.init(secretKeySpec);
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/prf/HkdfStreamingPrf.java:83:            this.mac.init(new SecretKeySpec(this.prk, HkdfStreamingPrf.getJavaxHmacName(HkdfStreamingPrf.this.hashType)));
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/AesCmac.java:8:import javax.crypto.SecretKey;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/AesCmac.java:9:import javax.crypto.spec.SecretKeySpec;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/crypto/tink/subtle/AesCmac.java:13:    private final SecretKey keySpec;
```

### Détail : `api_key`
```java
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/o/i.java:174:                    i.this.t.i("Provided authentication credentials are invalid. This usually indicates your FirebaseApp instance was not initialized correctly. Make sure your google-services.json file has the correct firebase_url and api_key. You can re-download google-services.json from https://console.firebase.google.com/.");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/auth/z/a/p0.java:80:            z2.putString("com.google.firebase.auth.API_KEY", v0Var.d());
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/b/c/c/h.java:44:        return new h(a2, vVar.a("google_api_key"), vVar.a("firebase_database_url"), vVar.a("ga_trackingId"), vVar.a("gcm_defaultSenderId"), vVar.a("google_storage_bucket"), vVar.a("project_id"));
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/b3nac/injuredandroid/R.java:2215:        public static final int google_api_key = 0x7f0f0076;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/b3nac/injuredandroid/R.java:2217:        public static final int google_crash_reporting_api_key = 0x7f0f0078;
```

### Détail : `token`
```java
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/c/b/a.java:94:            b.c.b.a.d.b(!str.isEmpty(), "token must have at least 1 tchar");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/c/a/c/a/d.java:6:import org.json.JSONTokener;
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/c/a/c/a/d.java:40:            JSONTokener jSONTokener = new JSONTokener(s.f1507b.b(byteBuffer));
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/c/a/c/a/d.java:41:            Object nextValue = jSONTokener.nextValue();
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/c/a/c/a/d.java:42:            if (jSONTokener.more()) {
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/b.java:29:        f2003c.put(-6, "The supplied auth token has expired");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/b.java:30:        f2003c.put(-7, "The supplied auth token was invalid");
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/b.java:44:        f2004d.put("expired_token", -6);
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/b.java:45:        f2004d.put("invalid_token", -7);
/home/user/IoT/formation-Jour2/android-analysis/injured_out/sources/com/google/firebase/database/t/b.java:14:import org.json.JSONTokener;
```


## 6. Ressources sensibles

### strings.xml (49 entrées)

**⚠ Entrées sensibles détectées :**
```xml
    <string name="abc_capital_off">DESACTIVAR</string>
    <string name="abc_capital_on">ACTIVAR</string>
```

### Fichiers de configuration détectés
```
firebase-database-collection.properties
play-services-base.properties
build-data.properties
firebase-auth-interop.properties
firebase-common.properties
res/xml/standalone_badge_gravity_bottom_end.xml
res/xml/standalone_badge_gravity_bottom_start.xml
res/xml/network_security_config.xml
res/xml/standalone_badge.xml
res/xml/file_paths.xml
res/xml/standalone_badge_gravity_top_start.xml
res/values-gl/strings.xml
res/values-or/strings.xml
res/values-w480dp-port/dimens.xml
res/values-vi/strings.xml
res/values-b+sr+Latn/strings.xml
res/values-ta/strings.xml
res/values-hr/strings.xml
res/values-is/strings.xml
res/values-da/strings.xml
res/values-be/strings.xml
res/values-ms/strings.xml
res/values-iw/strings.xml
res/layout-watch/abc_alert_dialog_button_bar_material.xml
res/layout-watch/abc_alert_dialog_title_material.xml
res/values-bn/strings.xml
res/values-v26/styles.xml
res/values-pt-rBR/strings.xml
res/values-es-rUS/strings.xml
res/values-fr/strings.xml
res/drawable-v24/ic_launcher_foreground.xml
res/drawable-v24/res_0x7f070006_ic_launcher_foreground__0.xml
res/values-mdpi/drawables.xml
res/values-sw/strings.xml
res/values-bs/strings.xml
res/values-en-rCA/strings.xml
res/values-hdpi/drawables.xml
res/values-hdpi/styles.xml
res/layout-land/mtrl_picker_header_dialog.xml
res/values-th/strings.xml
res/values-hi/strings.xml
res/values-en-rAU/strings.xml
res/values-ru/strings.xml
res/values-v24/drawables.xml
res/values-v24/styles.xml
res/values-land/dimens.xml
res/values-land/integers.xml
res/values-land/styles.xml
res/values-es/strings.xml
res/values-zh-rTW/strings.xml
res/mipmap-anydpi-v26/ic_launcher_round.xml
res/mipmap-anydpi-v26/support.xml
res/mipmap-anydpi-v26/ic_launcher.xml
res/mipmap-anydpi-v26/support_round.xml
res/mipmap-anydpi-v26/b3nac_logo.xml
res/mipmap-anydpi-v26/b3nac_logo_round.xml
res/values-sw600dp/dimens.xml
res/values-sw600dp/integers.xml
res/values-sw600dp/styles.xml
res/drawable-anydpi/design_ic_visibility_off.xml
res/drawable-anydpi/design_ic_visibility.xml
res/values-ja/strings.xml
res/values-kk/strings.xml
res/values-zu/strings.xml
res/values-zh-rHK/strings.xml
res/values-zh-rCN/strings.xml
res/values-h720dp/dimens.xml
res/menu/menu_main.xml
res/values-pl/strings.xml
res/drawable/mtrl_ic_cancel.xml
res/drawable/btn_radio_off_to_on_mtrl_animation.xml
res/drawable/design_snackbar_background.xml
res/drawable/common_google_signin_btn_icon_dark.xml
res/drawable/design_password_eye.xml
res/drawable/common_google_signin_btn_text_light_normal.xml
res/drawable/abc_list_selector_background_transition_holo_light.xml
res/drawable/ic_launcher_background.xml
res/drawable/abc_ratingbar_material.xml
res/drawable/mtrl_ic_arrow_drop_down.xml
res/drawable/avd_hide_password.xml
res/drawable/mtrl_ic_arrow_drop_up.xml
res/drawable/abc_action_bar_item_background_material.xml
res/drawable/tooltip_frame_light.xml
res/drawable/mtrl_ic_error.xml
res/drawable/res_0x7f070005_avd_show_password__2.xml
res/drawable/tooltip_frame_dark.xml
res/drawable/btn_checkbox_unchecked_to_checked_mtrl_animation.xml
res/drawable/abc_btn_colored_material.xml
res/drawable/common_google_signin_btn_text_dark_normal.xml
res/drawable/ic_mtrl_chip_close_circle.xml
res/drawable/common_google_signin_btn_text_dark.xml
res/drawable/mtrl_dropdown_arrow.xml
res/drawable/notification_bg.xml
res/drawable/mtrl_popupmenu_background.xml
res/drawable/ic_clear_black_24dp.xml
res/drawable/avd_show_password.xml
res/drawable/abc_ratingbar_indicator_material.xml
res/drawable/design_bottom_navigation_item_background.xml
res/drawable/btn_radio_off_mtrl.xml
res/drawable/abc_list_divider_material.xml
res/drawable/res_0x7f070004_avd_show_password__1.xml
res/drawable/abc_ic_ab_back_material.xml
res/drawable/notification_tile_bg.xml
res/drawable/common_google_signin_btn_icon_light_normal.xml
res/drawable/common_google_signin_btn_icon_light_focused.xml
res/drawable/abc_ic_arrow_drop_right_black_24dp.xml
res/drawable/btn_radio_on_mtrl.xml
res/drawable/abc_tab_indicator_material.xml
res/drawable/abc_ic_menu_overflow_material.xml
res/drawable/b3nac_logo_background.xml
res/drawable/btn_radio_on_to_off_mtrl_animation.xml
res/drawable/abc_switch_thumb_material.xml
res/drawable/common_google_signin_btn_icon_disabled.xml
res/drawable/abc_btn_check_material_anim.xml
res/drawable/abc_list_selector_holo_dark.xml
res/drawable/abc_btn_check_material.xml
res/drawable/res_0x7f070003_avd_show_password__0.xml
res/drawable/abc_textfield_search_material.xml
res/drawable/navigation_empty_icon.xml
res/drawable/ic_edit_black_24dp.xml
res/drawable/abc_ratingbar_small_material.xml
res/drawable/abc_seekbar_tick_mark_material.xml
res/drawable/ic_menu_arrow_up_black_24dp.xml
res/drawable/ic_mtrl_checked_circle.xml
res/drawable/test_custom_background.xml
res/drawable/mtrl_tabs_default_indicator.xml
res/drawable/notification_icon_background.xml
res/drawable/abc_btn_radio_material_anim.xml
res/drawable/abc_spinner_textfield_background_material.xml
res/drawable/abc_btn_default_mtrl_shape.xml
res/drawable/abc_btn_borderless_material.xml
res/drawable/abc_ic_search_api_material.xml
res/drawable/ic_mtrl_chip_checked_circle.xml
res/drawable/ic_menu_arrow_down_black_24dp.xml
res/drawable/btn_checkbox_unchecked_mtrl.xml
res/drawable/abc_ic_voice_search_api_material.xml
res/drawable/abc_text_cursor_material.xml
res/drawable/abc_vector_test.xml
res/drawable/common_google_signin_btn_icon_dark_normal.xml
res/drawable/abc_edit_text_material.xml
res/drawable/mtrl_popupmenu_background_dark.xml
res/drawable/mtrl_dialog_background.xml
res/drawable/ic_keyboard_arrow_right_black_24dp.xml
res/drawable/ic_calendar_black_24dp.xml
res/drawable/abc_seekbar_track_material.xml
res/drawable/common_google_signin_btn_icon_light.xml
res/drawable/common_google_signin_btn_text_light_focused.xml
res/drawable/abc_ic_clear_material.xml
res/drawable/abc_cab_background_top_material.xml
res/drawable/common_google_signin_btn_text_disabled.xml
res/drawable/abc_item_background_holo_light.xml
res/drawable/common_google_signin_btn_icon_dark_focused.xml
res/drawable/common_google_signin_btn_text_light.xml
res/drawable/res_0x7f070002_avd_hide_password__2.xml
res/drawable/abc_list_selector_holo_light.xml
res/drawable/ic_keyboard_arrow_left_black_24dp.xml
res/drawable/design_fab_background.xml
res/drawable/ic_mtrl_chip_checked_black.xml
res/drawable/abc_item_background_holo_dark.xml
res/drawable/res_0x7f070000_avd_hide_password__0.xml
res/drawable/abc_list_selector_background_transition_holo_dark.xml
res/drawable/abc_ic_go_search_api_material.xml
res/drawable/btn_checkbox_checked_mtrl.xml
res/drawable/res_0x7f070001_avd_hide_password__1.xml
res/drawable/support_background.xml
res/drawable/btn_checkbox_checked_to_unchecked_mtrl_animation.xml
res/drawable/common_google_signin_btn_text_dark_focused.xml
res/drawable/abc_cab_background_internal_bg.xml
res/drawable/abc_dialog_material_background.xml
res/drawable/notification_action_background.xml
res/drawable/abc_seekbar_thumb_material.xml
res/drawable/abc_btn_radio_material.xml
res/drawable/notification_bg_low.xml
res/values-h360dp-land/dimens.xml
res/values-night/styles.xml
res/values-ar/strings.xml
res/values-my/strings.xml
res/values-tl/strings.xml
res/layout/mtrl_picker_header_toggle.xml
res/layout/mtrl_alert_dialog.xml
res/layout/activity_flag_one_success.xml
res/layout/mtrl_layout_snackbar.xml
res/layout/select_dialog_item_material.xml
res/layout/activity_display_post_xss.xml
res/layout/support_simple_spinner_dropdown_item.xml
res/layout/abc_action_mode_close_item_material.xml
res/layout/activity_flag_eight_login.xml
res/layout/content_flags_overview.xml
res/layout/activity_deep_link.xml
res/layout/abc_activity_chooser_view_list_item.xml
res/layout/test_toolbar_surface.xml
res/layout/test_toolbar_custom_background.xml
res/layout/content_rce.xml
res/layout/activity_exported_protected_intent.xml
res/layout/abc_search_dropdown_item_icons_2line.xml
res/layout/design_bottom_sheet_dialog.xml
res/layout/mtrl_picker_header_fullscreen.xml
res/layout/mtrl_calendar_day_of_week.xml
res/layout/notification_template_custom_big.xml
res/layout/abc_search_view.xml
res/layout/abc_screen_toolbar.xml
res/layout/notification_action_tombstone.xml
res/layout/mtrl_calendar_months.xml
res/layout/design_layout_tab_icon.xml
res/layout/mtrl_picker_header_dialog.xml
res/layout/abc_activity_chooser_view.xml
res/layout/test_design_checkbox.xml
res/layout/activity_xsstext.xml
res/layout/test_reflow_chipgroup.xml
res/layout/abc_list_menu_item_radio.xml
res/layout/design_layout_snackbar.xml
res/layout/activity_qxv0a.xml
res/layout/mtrl_calendar_month_navigation.xml
res/layout/custom_dialog.xml
res/layout/design_navigation_item_subheader.xml
res/layout/abc_screen_simple.xml
res/layout/content_c_s_p_bypass.xml
res/layout/abc_action_mode_bar.xml
res/layout/design_navigation_menu.xml
res/layout/design_navigation_menu_item.xml
res/layout/content_flag_seven_sqlite.xml
res/layout/text_view_with_line_height_from_appearance.xml
res/layout/mtrl_picker_fullscreen.xml
res/layout/content_flag_two.xml
res/layout/activity_flag_five.xml
res/layout/abc_alert_dialog_button_bar_material.xml
res/layout/mtrl_calendar_month.xml
res/layout/activity_flag_two.xml
res/layout/activity_b25l.xml
res/layout/abc_action_menu_item_layout.xml
res/layout/content_flag_three.xml
res/layout/test_toolbar.xml
res/layout/abc_popup_menu_header_item_layout.xml
res/layout/text_view_without_line_height.xml
res/layout/activity_assembly.xml
res/layout/test_toolbar_elevation.xml
res/layout/activity_test_broadcast_reciever.xml
res/layout/abc_screen_content_include.xml
res/layout/content_deep_link.xml
res/layout/mtrl_alert_select_dialog_item.xml
res/layout/mtrl_picker_text_input_date_range.xml
res/layout/activity_main.xml
res/layout/select_dialog_multichoice_material.xml
res/layout/activity_flag_three.xml
res/layout/select_dialog_singlechoice_material.xml
res/layout/mtrl_picker_header_selection_text.xml
res/layout/content_flag_nine_firebase.xml
res/layout/abc_screen_simple_overlay_action_mode.xml
res/layout/design_text_input_start_icon.xml
res/layout/abc_expanded_menu_layout.xml
res/layout/abc_list_menu_item_icon.xml
res/layout/mtrl_calendar_year.xml
res/layout/content_flag_twelve_exported.xml
res/layout/text_view_with_theme_line_height.xml
res/layout/design_navigation_item_separator.xml
res/layout/abc_dialog_title_material.xml
res/layout/design_layout_snackbar_include.xml
res/layout/mtrl_alert_select_dialog_singlechoice.xml
res/layout/notification_template_part_chronometer.xml
res/layout/activity_flag_four.xml
res/layout/abc_action_bar_title_item.xml
res/layout/notification_template_part_time.xml
res/layout/content_flag_ten_unicode.xml
res/layout/content_flag_eight_login.xml
res/layout/activity_c_s_p_bypass.xml
res/layout/activity_flag_seven_sqlite.xml
res/layout/design_navigation_item_header.xml
res/layout/content_flag_six_login.xml
res/layout/activity_flag_twelve_exported.xml
res/layout/content_exported_protected_intent.xml
res/layout/mtrl_layout_snackbar_include.xml
res/layout/design_layout_tab_text.xml
res/layout/mtrl_alert_select_dialog_multichoice.xml
res/layout/abc_select_dialog_material.xml
res/layout/design_bottom_navigation_item.xml
res/layout/activity_flag_one_login.xml
res/layout/abc_tooltip.xml
res/layout/design_menu_item_action_area.xml
res/layout/mtrl_picker_actions.xml
res/layout/mtrl_calendar_days_of_week.xml
res/layout/mtrl_picker_dialog.xml
res/layout/activity_flag_seventeen.xml
res/layout/content_flag_one_login.xml
res/layout/mtrl_calendar_day.xml
res/layout/text_view_with_line_height_from_layout.xml
res/layout/content_flag_seventeen.xml
res/layout/abc_action_menu_layout.xml
res/layout/abc_list_menu_item_checkbox.xml
res/layout/content_assembly.xml
res/layout/text_view_with_line_height_from_style.xml
res/layout/abc_list_menu_item_layout.xml
res/layout/abc_alert_dialog_material.xml
res/layout/activity_settings.xml
res/layout/design_text_input_end_icon.xml
res/layout/mtrl_picker_text_input_date.xml
res/layout/activity_flags_overview.xml
res/layout/content_flag_five.xml
res/layout/mtrl_calendar_month_labeled.xml
res/layout/content_test_broadcast_reciever.xml
res/layout/abc_alert_dialog_title_material.xml
res/layout/content_flag_four.xml
res/layout/design_navigation_item.xml
res/layout/activity_flag_ten_unicode.xml
res/layout/mtrl_alert_dialog_title.xml
res/layout/mtrl_calendar_horizontal.xml
res/layout/mtrl_alert_dialog_actions.xml
res/layout/activity_flag_nine_firebase.xml
res/layout/activity_flag_six_login.xml
res/layout/abc_popup_menu_item_layout.xml
res/layout/activity_contact.xml
res/layout/activity_flag_eighteen.xml
res/layout/test_action_chip.xml
res/layout/abc_action_bar_up_container.xml
res/layout/activity_rce.xml
res/layout/mtrl_calendar_vertical.xml
res/layout/mtrl_picker_header_title_text.xml
res/layout/content_flag_eighteen.xml
res/layout/abc_cascading_menu_item_layout.xml
res/layout/notification_template_icon_group.xml
res/layout/notification_action.xml
res/values-sl/strings.xml
res/values-az/strings.xml
res/values-fi/strings.xml
res/values-anydpi/drawables.xml
res/values-kn/strings.xml
res/values-ml/strings.xml
res/values-si/strings.xml
res/values-xxhdpi/drawables.xml
res/values-large/dimens.xml
res/values-large/styles.xml
res/values-xlarge/dimens.xml
res/values-in/strings.xml
res/layout-v22/content_c_s_p_bypass.xml
res/layout-v22/content_flag_seven_sqlite.xml
res/layout-v22/abc_alert_dialog_button_bar_material.xml
res/layout-v22/content_flag_twelve_exported.xml
res/layout-v22/content_flag_ten_unicode.xml
res/layout-v22/content_flag_six_login.xml
res/layout-v22/content_flag_seventeen.xml
res/layout-v22/mtrl_alert_dialog_actions.xml
res/values-de/strings.xml
res/values-v25/styles.xml
res/layout-v26/abc_screen_toolbar.xml
res/layout-v26/mtrl_calendar_month.xml
res/values-lt/strings.xml
res/values-el/strings.xml
res/values-ro/strings.xml
res/values-am/strings.xml
res/values-uk/strings.xml
res/values-ur/strings.xml
res/values-gu/strings.xml
res/values-bg/strings.xml
res/values-ldrtl-xxhdpi/drawables.xml
res/values-en-rGB/strings.xml
res/values-it/strings.xml
res/values-cs/strings.xml
res/color-v23/abc_tint_spinner.xml
res/color-v23/abc_tint_edittext.xml
res/color-v23/abc_color_highlight_material.xml
res/color-v23/abc_btn_colored_text_material.xml
res/color-v23/abc_tint_default.xml
res/color-v23/abc_tint_seek_thumb.xml
res/color-v23/abc_tint_switch_track.xml
res/color-v23/abc_tint_btn_checkable.xml
res/color-v23/abc_btn_colored_borderless_text_material.xml
res/values-h480dp-land/dimens.xml
res/values-xhdpi/drawables.xml
res/values-pt/strings.xml
res/values-lv/strings.xml
res/values-v22/styles.xml
res/values-et/strings.xml
res/values-mr/strings.xml
res/values-km/strings.xml
res/values-hy/strings.xml
res/interpolator/btn_checkbox_checked_mtrl_animation_interpolator_1.xml
res/interpolator/btn_radio_to_off_mtrl_animation_interpolator_0.xml
res/interpolator/mtrl_linear_out_slow_in.xml
res/interpolator/btn_checkbox_unchecked_mtrl_animation_interpolator_0.xml
res/interpolator/mtrl_fast_out_slow_in.xml
res/interpolator/btn_checkbox_checked_mtrl_animation_interpolator_0.xml
res/interpolator/fast_out_slow_in.xml
res/interpolator/mtrl_linear.xml
res/interpolator/btn_checkbox_unchecked_mtrl_animation_interpolator_1.xml
res/interpolator/btn_radio_to_on_mtrl_animation_interpolator_0.xml
res/interpolator/mtrl_fast_out_linear_in.xml
res/values-tr/strings.xml
res/values-hu/strings.xml
res/values-ko/strings.xml
res/values-uz/strings.xml
res/values-sk/strings.xml
res/values-ky/strings.xml
res/values/colors.xml
res/values/attrs.xml
res/values/dimens.xml
res/values/drawables.xml
res/values/strings.xml
res/values/plurals.xml
res/values/integers.xml
res/values/public.xml
res/values/bools.xml
res/values/styles.xml
res/values-ne/strings.xml
res/values-fa/strings.xml
res/drawable-watch/abc_dialog_material_background.xml
res/values-watch/drawables.xml
res/values-watch/styles.xml
res/values-en-rXC/strings.xml
res/color/mtrl_calendar_selected_range.xml
res/color/mtrl_bottom_nav_ripple_color.xml
res/color/abc_tint_spinner.xml
res/color/mtrl_chip_text_color.xml
res/color/mtrl_btn_bg_color_selector.xml
res/color/mtrl_bottom_nav_colored_item_tint.xml
res/color/mtrl_tabs_icon_color_selector.xml
res/color/material_on_background_emphasis_high_type.xml
res/color/abc_hint_foreground_material_light.xml
res/color/mtrl_bottom_nav_colored_ripple_color.xml
res/color/mtrl_fab_ripple_color.xml
res/color/mtrl_chip_surface_color.xml
res/color/mtrl_tabs_ripple_color.xml
res/color/abc_background_cache_hint_selector_material_light.xml
res/color/abc_tint_edittext.xml
res/color/abc_secondary_text_material_dark.xml
res/color/mtrl_tabs_colored_ripple_color.xml
res/color/mtrl_btn_text_color_selector.xml
res/color/mtrl_btn_ripple_color.xml
res/color/mtrl_card_view_foreground.xml
res/color/mtrl_chip_ripple_color.xml
res/color/mtrl_extended_fab_ripple_color.xml
res/color/common_google_signin_btn_text_dark.xml
res/color/mtrl_popupmenu_overlay_color.xml
res/color/mtrl_filled_icon_tint.xml
res/color/material_on_surface_emphasis_high_type.xml
res/color/mtrl_extended_fab_text_color_selector.xml
res/color/design_icon_tint.xml
res/color/mtrl_btn_text_btn_ripple_color.xml
res/color/mtrl_btn_text_btn_bg_color_selector.xml
res/color/abc_primary_text_material_dark.xml
res/color/mtrl_on_primary_text_btn_text_color_selector.xml
res/color/mtrl_calendar_item_stroke_color.xml
res/color/material_on_primary_disabled.xml
res/color/checkbox_themeable_attribute_color.xml
res/color/mtrl_filled_stroke_color.xml
res/color/material_on_surface_emphasis_medium.xml
res/color/material_on_primary_emphasis_medium.xml
res/color/test_mtrl_calendar_day_selected.xml
res/color/mtrl_card_view_ripple.xml
res/color/mtrl_chip_background_color.xml
res/color/abc_secondary_text_material_light.xml
res/color/material_on_surface_disabled.xml
res/color/material_on_primary_emphasis_high_type.xml
res/color/abc_btn_colored_text_material.xml
res/color/abc_primary_text_material_light.xml
res/color/common_google_signin_btn_tint.xml
res/color/abc_tint_default.xml
res/color/mtrl_navigation_item_text_color.xml
res/color/mtrl_error.xml
res/color/mtrl_outlined_icon_tint.xml
res/color/mtrl_tabs_icon_color_selector_colored.xml
res/color/mtrl_btn_stroke_color_selector.xml
res/color/mtrl_tabs_legacy_text_color_selector.xml
res/color/abc_primary_text_disable_only_material_light.xml
res/color/abc_hint_foreground_material_dark.xml
res/color/abc_primary_text_disable_only_material_dark.xml
res/color/mtrl_extended_fab_bg_color_selector.xml
res/color/material_on_background_disabled.xml
res/color/switch_thumb_material_dark.xml
res/color/mtrl_filled_background_color.xml
res/color/abc_tint_seek_thumb.xml
res/color/abc_search_url_text.xml
res/color/switch_thumb_material_light.xml
res/color/mtrl_navigation_item_icon_tint.xml
res/color/abc_tint_switch_track.xml
res/color/design_box_stroke_color.xml
res/color/mtrl_outlined_stroke_color.xml
res/color/common_google_signin_btn_text_light.xml
res/color/mtrl_bottom_nav_item_tint.xml
res/color/mtrl_choice_chip_text_color.xml
res/color/test_mtrl_calendar_day.xml
res/color/mtrl_text_btn_text_color_selector.xml
res/color/material_on_background_emphasis_medium.xml
res/color/mtrl_indicator_text_color.xml
res/color/abc_tint_btn_checkable.xml
res/color/design_error.xml
res/color/abc_background_cache_hint_selector_material_dark.xml
res/color/mtrl_choice_chip_ripple_color.xml
res/color/mtrl_navigation_item_background_color.xml
res/color/mtrl_chip_close_icon_tint.xml
res/color/mtrl_choice_chip_background_color.xml
res/color/abc_btn_colored_borderless_text_material.xml
res/values-ldrtl-hdpi/drawables.xml
res/values-mn/strings.xml
res/values-eu/strings.xml
res/anim/btn_radio_to_off_mtrl_ring_outer_animation.xml
res/anim/btn_radio_to_off_mtrl_dot_group_animation.xml
res/anim/mtrl_bottom_sheet_slide_out.xml
res/anim/design_bottom_sheet_slide_in.xml
res/anim/nav_default_exit_anim.xml
res/anim/btn_checkbox_to_checked_box_outer_merged_animation.xml
res/anim/btn_radio_to_on_mtrl_ring_outer_path_animation.xml
res/anim/nav_default_pop_exit_anim.xml
res/anim/btn_checkbox_to_unchecked_check_path_merged_animation.xml
res/anim/abc_slide_out_top.xml
res/anim/btn_checkbox_to_checked_box_inner_merged_animation.xml
res/anim/abc_popup_exit.xml
res/anim/abc_shrink_fade_out_from_bottom.xml
res/anim/fragment_open_enter.xml
res/anim/design_bottom_sheet_slide_out.xml
res/anim/fragment_fade_exit.xml
res/anim/design_snackbar_out.xml
res/anim/abc_slide_out_bottom.xml
res/anim/fragment_close_exit.xml
res/anim/fragment_open_exit.xml
res/anim/fragment_fade_enter.xml
res/anim/nav_default_pop_enter_anim.xml
res/anim/abc_grow_fade_in_from_bottom.xml
res/anim/nav_default_enter_anim.xml
res/anim/abc_fade_out.xml
res/anim/fragment_fast_out_extra_slow_in.xml
res/anim/btn_checkbox_to_unchecked_icon_null_animation.xml
res/anim/fragment_close_enter.xml
res/anim/btn_checkbox_to_unchecked_box_inner_merged_animation.xml
res/anim/abc_tooltip_enter.xml
res/anim/btn_radio_to_on_mtrl_ring_outer_animation.xml
res/anim/abc_popup_enter.xml
res/anim/btn_radio_to_on_mtrl_dot_group_animation.xml
res/anim/design_snackbar_in.xml
res/anim/abc_tooltip_exit.xml
res/anim/btn_radio_to_off_mtrl_ring_outer_path_animation.xml
res/anim/btn_checkbox_to_checked_icon_null_animation.xml
res/anim/mtrl_bottom_sheet_slide_in.xml
res/anim/abc_slide_in_top.xml
res/anim/abc_fade_in.xml
res/anim/mtrl_card_lowers_interpolator.xml
res/anim/abc_slide_in_bottom.xml
res/layout-sw600dp/mtrl_layout_snackbar.xml
res/layout-sw600dp/design_layout_snackbar.xml
res/values-small/dimens.xml
res/values-mk/strings.xml
res/values-fr-rCA/strings.xml
res/values-ldrtl-xhdpi/drawables.xml
res/values-pa/strings.xml
res/values-en-rIN/strings.xml
res/values-sq/strings.xml
res/values-sv/strings.xml
res/drawable-v23/mtrl_popupmenu_background_dark.xml
res/drawable-v23/abc_control_background_material.xml
res/values-af/strings.xml
res/values-ca/strings.xml
res/values-v23/colors.xml
res/values-v23/drawables.xml
res/values-v23/styles.xml
res/values-xxxhdpi/drawables.xml
res/values-as/strings.xml
res/values-ka/strings.xml
res/animator/mtrl_extended_fab_show_motion_spec.xml
res/animator/mtrl_fab_transformation_sheet_expand_spec.xml
res/animator/nav_default_exit_anim.xml
res/animator/mtrl_card_state_list_anim.xml
res/animator/design_fab_show_motion_spec.xml
res/animator/design_fab_hide_motion_spec.xml
res/animator/nav_default_pop_exit_anim.xml
res/animator/design_appbar_state_list_animator.xml
res/animator/mtrl_fab_show_motion_spec.xml
res/animator/mtrl_chip_state_list_anim.xml
res/animator/mtrl_fab_hide_motion_spec.xml
res/animator/nav_default_pop_enter_anim.xml
res/animator/mtrl_btn_unelevated_state_list_anim.xml
res/animator/nav_default_enter_anim.xml
res/animator/mtrl_extended_fab_hide_motion_spec.xml
res/animator/mtrl_extended_fab_state_list_animator.xml
res/animator/mtrl_btn_state_list_anim.xml
res/animator/mtrl_extended_fab_change_size_motion_spec.xml
res/animator/mtrl_fab_transformation_sheet_collapse_spec.xml
res/values-sr/strings.xml
res/values-nl/strings.xml
res/values-lo/strings.xml
res/values-port/bools.xml
res/values-ldrtl-xxxhdpi/drawables.xml
res/values-w360dp-port/dimens.xml
res/values-te/strings.xml
res/values-pt-rPT/strings.xml
res/values-nb/strings.xml
res/values-v28/dimens.xml
res/values-v28/styles.xml
res/values-ldltr/styles.xml
res/values-ldrtl-mdpi/drawables.xml
firebase-database.properties
play-services-basement.properties
assets/flutter_assets/AssetManifest.json
assets/flutter_assets/FontManifest.json
play-services-tasks.properties
firebase-firestore.properties
firebase-components.properties
AndroidManifest.xml
protolite-well-known-types.properties
firebase-auth.properties
```

## 7. Scripts Frida générés

| Script | Objectif | Statut |
|---|---|---|
| `bypass_root.js` | Contourner la détection root | ✔ Prêt (23 lignes) |
| `bypass_ssl.js` | Désactiver SSL pinning (verifyChain + OkHttp3) | ✔ Prêt (35 lignes) |
| `list_activities.js` | Lister toutes les activités exportées | ✔ Prêt (21 lignes) |
| `dump_prefs.js` | Dump SharedPreferences en clair | ✔ Prêt (18 lignes) |
| `hook_flag.js` | Hook méthode submitFlag — bypass auth | ✔ Prêt (34 lignes) |

### hook_flag.js
```javascript
// Hook méthode submitFlag — InjuredAndroid
// frida -U -l hook_flag.js -f b3nac.injuredandroid --no-pause
Java.perform(function() {
  console.log("[*] Hook InjuredAndroid chargé");
  try {
    var FlagOne = Java.use('b3nac.injuredandroid.FlagOneActivity');
    FlagOne.submitFlag.overloads.forEach(function(o) {
      o.implementation = function() {
        var args = Array.prototype.slice.call(arguments);
        console.log('[FLAG1] submitFlag(' + JSON.stringify(args) + ')');
        // Pour forcer le bon flag :
        // return o.apply(this, ['the_real_flag']);
        return o.apply(this, arguments);
      };
    });
    console.log("[+] FlagOneActivity hookée");
  } catch(e) { console.log("[-] " + e); }

  // Scan toutes les méthodes de l'app
  Java.enumerateLoadedClasses({
    onMatch: function(name) {
      if (name.indexOf('b3nac') !== -1) {
        try {
          Java.use(name).class.getDeclaredMethods().forEach(function(m) {
            var mn = m.getName();
            if (/flag|submit|check|verify/i.test(mn))
              console.log('[MÉTHODE] ' + name + '.' + mn);
          });
        } catch(e) {}
      }
    },
    onComplete: function() {}
  });
});
```

### bypass_ssl.js
```javascript
// Bypass SSL Pinning — InjuredAndroid
// Combine les deux méthodes du TP (verifyChain + checkTrustedRecursive)
Java.perform(function() {
  console.log("[*] Bypass SSL Pinning chargé");

  // Méthode 1 : verifyChain (Android 11+ / TP doc v2)
  try {
    var TM = Java.use('com.android.org.conscrypt.TrustManagerImpl');
    TM.verifyChain.implementation = function() {
      console.log('[SSL] verifyChain bypassed');
      return arguments[0];
    };
    console.log("[+] TrustManagerImpl.verifyChain bypassed");
  } catch(e) { console.log("[-] verifyChain absent : " + e); }

  // Méthode 2 : checkTrustedRecursive (Android < 11)
  try {
    var TM2 = Java.use('com.android.org.conscrypt.TrustManagerImpl');
    TM2.checkTrustedRecursive.implementation = function() {
      console.log('[SSL] checkTrustedRecursive bypassed');
      return Java.use('java.util.ArrayList').$new();
    };
    console.log("[+] TrustManagerImpl.checkTrustedRecursive bypassed");
  } catch(e) { console.log("[-] checkTrustedRecursive absent : " + e); }

  // Méthode 3 : OkHttp3 CertificatePinner
  try {
    var CP = Java.use('okhttp3.CertificatePinner');
    CP.check.overload('java.lang.String','java.util.List').implementation =
      function(h,c) { console.log('[SSL] OkHttp3 CertificatePinner(' + h + ') bypassed'); };
    console.log("[+] OkHttp3 SSL pinning bypassed");
  } catch(e) { console.log("[-] OkHttp3 absent : " + e); }

  console.log("[+] SSL bypass complet");
});
```

### bypass_root.js
```javascript
// Bypass Root Detection — InjuredAndroid
Java.perform(function() {
  console.log("[*] Bypass root detection");
  try {
    var RB = Java.use('com.scottyab.rootbeer.RootBeer');
    RB.isRooted.overload().implementation = function() {
      console.log('[ROOT] isRooted() -> false');
      return false;
    };
    RB.isRootedWithoutBusyBoxCheck.implementation = function() { return false; };
    console.log("[+] RootBeer bypassed");
  } catch(e) { console.log("[-] RootBeer absent : " + e); }
  var File = Java.use('java.io.File');
  File.exists.implementation = function() {
    var p = this.getAbsolutePath();
    if (/su|busybox|superuser/i.test(p)) {
      console.log('[ROOT] File.exists(' + p + ') -> false');
      return false;
    }
    return this.exists();
  };
  console.log("[+] Root detection bypass actif");
});
```

## 8. Émulateur Android (Docker)

- **Docker :** Docker version 28.2.2, build 28.2.2-0ubuntu1~24.04.1
- **Image :** budtmo/docker-android:emulator_11.0 ✔
- **Émulateur :** ⚠ non démarré

Pour démarrer :
```bash
docker run -d -p 6080:6080 -p 5555:5555 \
  -e EMULATOR_DEVICE="Samsung Galaxy S10" \
  --privileged budtmo/docker-android:emulator_11.0
```

## 9. ADB & Connexion émulateur

- **ADB :** Android Debug Bridge version 1.0.41
- **Appareils :** ⚠ aucun connecté

## 10. Inventaire des fichiers produits

| Fichier | Taille | Statut |
|---|---|---|
| APK InjuredAndroid | 24M | ✔ |
| Frida-server Android x86 | — | ⚠ |
| Analyse Manifest | 4,0K | ✔ |
| Secrets hardcodés | 20K | ✔ |
| Ressources | 8,0K | ✔ |
| Rapport vulnérabilités | 4,0K | ✔ |
| Guide Frida | 4,0K | ✔ |
| Guide Objection | 4,0K | ✔ |
| Guide Docker | 4,0K | ✔ |
| Script hook_flag | 4,0K | ✔ |
| Script bypass_root | 4,0K | ✔ |
| Script bypass_ssl | 4,0K | ✔ |
| Script dump_prefs | 4,0K | ✔ |
| Script list_activities | 4,0K | ✔ |

---
## Synthèse des vulnérabilités identifiées

| # | Vulnérabilité | Vecteur | Criticité | Statut |
|---|---|---|---|---|
| V1 | Activités exportées sans permission (7) | IPC Android | **Critique** | ✔ Détectée |
| V2 | Secrets hardcodés dans le code | Analyse statique | **Critique** | ✔ Détectée |
| V3 | SharedPreferences en clair | Accès fichiers | Élevée | ✔ Confirmée |
| V4 | Auth côté client (hookable Frida) | Analyse dynamique | **Critique** | ✔ Scriptée |
| V5 | Root detection contournable | Frida/Objection | Élevée | ✔ Scriptée |
| V6 | SSL Pinning contournable | Frida verifyChain | Élevée | ✔ Scriptée |

## Procédures d'exploitation

### V1 — Bypass auth via activité exportée
```bash
# Sans émulateur (ADB direct)
adb shell am start -n b3nac.injuredandroid/.FlagEightLogInActivity

# Via Objection
objection -g b3nac.injuredandroid explore
android intent launch_activity b3nac.injuredandroid.FlagEightLogInActivity
```

### V4 — Bypass auth via Frida (hook submitFlag)
```bash
# Démarrer frida-server sur l'émulateur
adb push /home/user/IoT/formation-Jour2/android-analysis/frida-server/frida-server /data/local/tmp/frida-server
adb shell 'chmod 755 /data/local/tmp/frida-server && /data/local/tmp/frida-server &'

# Lancer le hook
frida -U -l /home/user/IoT/formation-Jour2/android-analysis/frida-scripts/hook_flag.js -f b3nac.injuredandroid --no-pause
```

### V5+V6 — Bypass root + SSL via Objection
```bash
objection -g b3nac.injuredandroid explore
android root disable
android sslpinning disable
android preferences get
```

---
## Résultats des tests

| | Résultat |
|---|---|
| ✔ Tests réussis | 34 / 51 |
| ✘ Tests échoués | 13 / 51 |
| ⚠ Avertissements | 4 / 51 |

> Rapport généré le 02/04/2026 à 14:30 par `test_and_report_tp5.sh`
