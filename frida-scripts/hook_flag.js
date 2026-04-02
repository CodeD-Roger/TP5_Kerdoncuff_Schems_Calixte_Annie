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
