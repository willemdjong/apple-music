/* eslint-disable global-require */
if (process.platform === 'darwin') {
  module.exports = require('bindings')('appleMusic');
}
