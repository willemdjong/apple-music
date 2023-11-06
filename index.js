/* eslint-disable global-require */
if (process.platform === "darwin") {
  module.exports = require("bindings")("apple_music");
}
