/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:collection';

///
/// A classic Stack of items with a push and pop method.
///
class StackList<T> {
  Queue<T> stack = Queue();

  StackList();

  ///
  /// Creates a stack from [initialStack]
  /// by pushing each element of the list
  /// onto the stack from first to last.
  StackList.fromList(List<T> initialStack) {
    for (final item in initialStack) {
      push(item);
    }
  }

  void push(T item) {
    stack.addFirst(item);
  }

  T pop() {
    return stack.removeFirst();
  }

  /// returns the item onf the top of the stack
  /// but does not remove the item.
  T peek() {
    return stack.first;
  }
}
