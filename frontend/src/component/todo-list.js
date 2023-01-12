const TodoList = ({ list, deleteTodo }) => {
  return (
    <>
      {list?.length > 0 ? (
        <ul className="todo-list">
          {list.map((entry, index) => (
            <div key={entry._id} className="todo">
              <li> {entry.description}</li>

              <button
                className="delete-button"
                onClick={() => {
                  deleteTodo(entry._id);
                }}
              >
                Delete
              </button>
            </div>
          ))}
        </ul>
      ) : (
        <div className="empty">
          <p>No Todos found</p>
        </div>
      )}
    </>
  );
};

export default TodoList;
