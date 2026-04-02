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
