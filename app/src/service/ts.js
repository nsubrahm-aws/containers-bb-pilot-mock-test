'use strict';

const dbops = require('../rds/get');

exports.getTs = function (req) {
  return new Promise(function (resolve, reject) {
    dbops.getTs(req, (err, res) => {
      if (err) {
        reject({
          code: 500,
          payload: { msg: err.msg }
        })        
      } else {
        resolve({
          code: 200,
          payload: {
            ts: res.ts
          }
        })
      }
    })
  });
}