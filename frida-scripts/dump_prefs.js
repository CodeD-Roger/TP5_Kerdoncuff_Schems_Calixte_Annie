// Dump SharedPreferences — InjuredAndroid
Java.perform(function() {
  console.log("[*] Dump SharedPreferences actif");
  var SP = Java.use('android.app.SharedPreferencesImpl');
  SP.getString.overload('java.lang.String','java.lang.String').implementation =
    function(k,d) {
      var v = this.getString(k,d);
      if (v !== d) console.log('[PREFS] ' + k + ' = ' + v);
      return v;
    };
  var Act = Java.use('android.app.Activity');
  Act.getSharedPreferences.overload('java.lang.String','int').implementation =
    function(n,m) {
      console.log('[PREFS FILE] ' + n);
      return this.getSharedPreferences(n,m);
    };
  console.log("[+] Hooks SharedPreferences actifs");
});
