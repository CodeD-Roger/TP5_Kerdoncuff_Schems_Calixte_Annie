// Liste toutes les activités — InjuredAndroid
Java.perform(function() {
  var AT = Java.use('android.app.ActivityThread');
  var ctx = AT.currentApplication().getApplicationContext();
  var pm = ctx.getPackageManager();
  var pkg = ctx.getPackageName();
  try {
    var info = pm.getPackageInfo(pkg, 0x00000008);
    var acts = info.activities.value;
    console.log("\n[+] Activités (" + (acts ? acts.length : 0) + ") :");
    if (acts) acts.forEach(function(a) {
      var exported = a.exported.value;
      var perm = a.permission.value;
      console.log(
        (exported ? "[EXPORTED] " : "[private]  ") +
        a.name.value +
        (perm ? " [perm:" + perm + "]" : "")
      );
    });
  } catch(e) { console.log("[-] " + e); }
});
