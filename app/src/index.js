const express = require('express')
const bp = require('body-parser')
const morgan = require('morgan')

const tsSvc = require('./service/ts')
const logger = require('./utils/logger')
const appConfig = require('./utils/config').getAppConfig()

if (Object.keys(appConfig).length === 0) {
  logger.error(`Configuration data was not received.`)
  process.exit(1)
}

const app = express()

app.use(morgan('dev'))
app.use(bp.json())

const serverPort = process.env.PORT || 3000;

app.get('/ping', (req, res) => {
  res.status(200).json({
    msg: 'OK'
  })
})

app.post('/demo/ts', (req, res) => {
  tsSvc.getTs({
    requestHeader: req.get('X-Amzn-Trace-Id'),
    rdsConfig: appConfig.rds
  })
    .then((resp) => {
      res.status(resp.code).json(resp.payload)
    })
    .catch((resp) => {
      res.status(resp.code).json(resp.payload)
    })
})

app.use('/', (req, res) => {
  res.status(404).json({
    msg: `${req.path} is not supported.`
  })
})

app.listen(serverPort, () => {
  logger.info(`Time-stamp microservice is up at ${serverPort}`)
})
