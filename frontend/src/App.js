import { useState, useEffect } from "react";
import TodoService from "./api/todo";
import TodoInput from "./component/todo-input";
import TodoList from "./component/todo-list";
import "./App.css";

const App = () => {
  const [todos, setTodos] = useState([]);
  const [todo, setTodo] = useState("");
  
  const loadTodos = async () => {
    try {
      const response = await TodoService.getTodos();
      const todos = response.data;

      setTodos(todos);
    } catch (error) {
      
    } 
  };

  useEffect(() => {
    loadTodos();
  }, []);

  const addTodo = async (text) => {
    if (text !== "") {
      await TodoService.addTodo(text);
      setTodo("");
      loadTodos();
    }
  };

  const deleteTodo = async (id) => {
    await TodoService.deleteTodo(id);
    loadTodos();
  };

  return (
    <div className="App">
      <h1>Todo App</h1>
      <TodoInput todo={todo} setTodo={setTodo} addTodo={addTodo} />
      <TodoList list={todos} deleteTodo={deleteTodo}/>
    </div>
  );
};

export default App;
