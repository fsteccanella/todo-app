const TodoInput = ({todo, setTodo, addTodo }) => {
  return (
    <div className="input-wrapper">
      <input
        type="text"
        name="todo"
        onChange = {(e) => setTodo(e.target.value)}
        value={todo}
        placeholder="Create a new todo"
      />
      <button className="add-button" onClick={() => { addTodo(todo) }}>
        Add
      </button>
    </div>
  );
};

export default TodoInput;
