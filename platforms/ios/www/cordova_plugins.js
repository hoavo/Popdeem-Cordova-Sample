cordova.define('cordova/plugin_list', function(require, exports, module) {
  module.exports = [
    {
      "id": "popdeem-cordova-plugin.popdeem",
      "file": "plugins/popdeem-cordova-plugin/www/popdeem.js",
      "pluginId": "popdeem-cordova-plugin",
      "clobbers": [
        "popdeem"
      ]
    }
  ];
  module.exports.metadata = {
    "cordova-plugin-whitelist": "1.3.2",
    "popdeem-cordova-plugin": "0.1.30"
  };
});