import Axios from "axios";

const axios = Axios.create({
    baseURL: process.env.REACT_APP_TODO_API_BASE_URL || ""
});

const TodoService = {
    getTodos: async () => {
        return axios.get("/api/todos");
    },

    addTodo: async (text) => {
        return axios.post("/api/todos", {"description": text});
    },

    toggleTodo: async (id, done) => {
        return axios({
            url: `/api/todos/${id}`,
            method: "patch",
            data: {
                done: !done
            }
        });
    },

    deleteTodo: async (id) => {
        return axios({
            url: `/api/todos/${id}`,
            method: "delete"
        });
    },
}

export default TodoService
