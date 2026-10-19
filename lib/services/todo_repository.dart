import '../models/todo_item.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> getTodos();
  Future<TodoItem> insertTodo(TodoItem todo);
  Future<void> updateTodo(TodoItem todo);
  Future<void> deleteTodo(int id);
}
