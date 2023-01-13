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

const todoService = require('./service/todo.js');
todoService.register(router, '/todos');

server.listen(port, () => {
  console.log(`BACKEND is running on port ${port}`);
});