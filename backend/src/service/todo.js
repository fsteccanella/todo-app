const restful = require('node-restful');

const todoSchema = require('../model/todo.js');
const todoService = restful.model('Todo', todoSchema);

todoService.methods(['get', 'post', 'put', 'delete']);
todoService.updateOptions({
  new: true,
  runValidators: true,
});

module.exports = todoService;