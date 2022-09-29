'use strict';

const mysql = require('mysql2');
const AWS = require('aws-sdk');

const logger = require('../utils/logger')

const TZ = process.env.TZ || 'Asia/Kolkata'

function getToken(dbConfig, requestId, cb) {
  var signer = new AWS.RDS.Signer();
  signer.getAuthToken({
    region: dbConfig.region,
    hostname: dbConfig.host,
    port: dbConfig.port,
    username: dbConfig.dbuser
  }, (err, token) => {
    if (err) {
      logger.error(`Request ID: ${requestId} - Error getting token ${err.code}`)
      cb(err, null)
    } else {
      logger.info(`Request ID: ${requestId} - Obtained token.`)
      dbConfig.token = token
      cb(null, dbConfig)
    }
  })
}

function getDbConnection(dbConfig, requestId, cb) {
  var conn = mysql.createConnection({
    host: dbConfig.host,
    port: dbConfig.port,
    user: dbConfig.dbuser,
    password: dbConfig.token,
    database: dbConfig.db,
    ssl: 'Amazon RDS',
    authPlugins: {
      mysql_clear_password: () => () => Buffer.from(dbConfig.token + '\0')
    }
  });

  conn.connect((err) => {
    if (err) {
      logger.error(`Request ID: ${requestId} - Database connection failed - ${err.code} ${err.message}`)
      cb(err, null)
    } else {
      logger.info(`Request ID: ${requestId} - Database connected.`)
      cb(null, conn)
    }
  })
}

function getTs(req, cb) {
  let requestId = req.requestHeader
  let dbConfig = req.rdsConfig

  getToken(dbConfig, requestId, (iamErr, dbToken) => {
    if (iamErr) {
      logger.error(`Request ID: ${requestId} - IAM error - ${iamErr.code} ${iamErr.message}`)
      cb(iamErr, null)
    } else {
      getDbConnection(dbToken, requestId, (dbErr, conn) => {
        if (dbErr) {
          logger.error(`Request ID: ${requestId} - Database connection error - ${dbErr.code} ${dbErr.message}`)
          cb(dbErr, null)
        } else {
          let q = `SELECT CURRENT_TIMESTAMP as currentTs;`
          conn.query(q, (qryErr, results, fields) => {
            if (qryErr) {
              logger.error(`Request ID: ${requestId} - Database query error - ${qryErr.code} ${qryErr.message}`)
              cb(qryErr, null)
            } else {
              cb(null, { ts: results[0].currentTs })
            }
          })
        }
      })
    }
  })
}

module.exports = {
  getTs: getTs
}