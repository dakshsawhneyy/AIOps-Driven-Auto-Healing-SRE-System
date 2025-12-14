const express = require("express");
//const cors = require("cors");
const promClient = require('prom-client');
const morgan = require('morgan');
const pino = require('pino')

const app = express();

// Creating logger and logging fxn using pino -- fluentbit can easily fetch these logs
const logger = pino();
const logging = () => {
    logger.info('Hello from Service A - Daksh Sawhney');
    logger.error('This is an error log from Service A - Daksh Sawhney');
    logger.warn('This is a warning log from Service A - Daksh Sawhney');
    logger.debug('This is a debug log from Service A - Daksh Sawhney');
    logger.fatal('This is a fatal log from Service A - Daksh Sawhney');
    logger.info("This is just for testing");
}


// Prometheus Metrics
const httpRequestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'path', 'status_code']
}) 
const httpRequestDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'path', 'status_code'],
    buckets: [0.1, 0.5, 1, 2.5, 5, 10]      // Buckets for the histogram in seconds
})
const requestDurationSummary = new promClient.Summary({
    name: 'http_request_duration_summary_seconds',
    help: 'Summary of HTTP request durations in seconds',
    labelNames: ['method', 'path', 'status_code'],
    percentiles: [0.5, 0.9, 0.99]           // Percentiles to calculate
})


app.use(morgan('common'))   // logs everything and sends them as stdout

// Middleware to parse JSON requests and adding labels to metrics so it can track metrics
app.use((req,res,next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        console.log(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}s`);

        httpRequestCounter.labels( req.method, req.path, res.statusCode ).inc();
        httpRequestDuration.labels( req.method, req.path, res.statusCode ).observe(duration);
        requestDurationSummary.labels( req.method, req.path, res.statusCode ).observe(duration);
    })
    next();
})


// parse requests of content-type - application/json
app.use(express.json());

// parse requests of content-type - application/x-www-form-urlencoded
app.use(express.urlencoded({ extended: true }));

const db = require("./app/models");
db.mongoose
  .connect(db.url, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  })
  .then(() => {
    console.log("Connected to the database!");
  })
  .catch(err => {
    console.log("Cannot connect to the database!", err);
    process.exit();
  });

// simple route
app.get("/", (req, res) => {
  res.json({ message: "Welcome to Test application." });
});

require("./app/routes/turorial.routes")(app);

app.get('/healthy', (req, res) => {
    res.status(200).json({
        name: "👀 - Obserability 🔥- Daksh Sawhney",
        status: "healthy"
    })
});

app.get('/metrics', async(req,res) => {
    res.set('Content-Type', promClient.register.contentType);
    const metrics = await promClient.register.metrics();
    res.end(metrics);
})

// set port, listen for requests
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}.`);
});
