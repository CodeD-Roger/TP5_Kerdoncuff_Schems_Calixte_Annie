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
