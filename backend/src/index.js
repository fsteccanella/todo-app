const port = process.env.API_PORT || 3001;

const bodyParser = require('body-parser');
const cors = require('cors');
const express = require('express');

const server = express();
server.use(cors());
server.use(bodyParser.urlencoded({ extended: true }));
server.use(bodyParser.json());

const router = express.Router();
server.use('/api', router);

const mongoose = require('mongoose');
mongoose.Promise = global.Promise;
const connectionString = `mongodb://${process.env.MONGO_SERVER || 'localhost'}/todo`;
mongoose.connect(connectionString);

async function closeGracefully(signal) {
  console.log(`*^!@4=> Received signal to terminate: ${signal}`)

  await mongoose.disconnect()

  server.close();

  process.exit(0);
}

const todoService = require('./service/todo.js');
todoService.register(router, '/todos');


server.use('/api', router);
server.get('/healthcheck', async (req, res) => {
  const readyState = await mongoose.connection.readyState
  if(readyState == 1){
    console.log('HealthCheck OK');
    res.status(200).send('OK');
  }else{
    console.log('HealthCheck KO');
    res.status(500).send('KO');
  }
})

server.listen(port, () => {
  console.log(`BACKEND is running on port ${port}`);
});

process.once('SIGINT', closeGracefully)
process.once('SIGTERM', closeGracefully)