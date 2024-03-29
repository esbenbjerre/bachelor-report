/*
 * Copyright 2020 Esben Bjerre
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace RedBlackTree {

  ///
  /// An immutable red-black tree implementation with keys
  /// of type `k` and values of type `v`.
  ///
  /// A red-black tree is a self-balancing binary search tree.
  /// Each node is either red or black, although a transitory
  /// color double-black is allowed during deletion.
  /// The red-black tree satisfy the following invariants.
  ///
  /// 1. For all nodes with key `x`,
  /// the left subtree contains only nodes with keys `y` < `x` and
  /// the right subtree contains only nodes with keys `z` > `x`.
  /// 2. No red node has a red parent.
  /// 3. Every path from the root to a leaf contains the same
  /// number of black nodes.
  ///
  pub enum RedBlackTree[k, v] {

    ///
    /// A black leaf.
    ///
    case Leaf

    ///
    /// A double-black leaf.
    ///
    case DoubleBlackLeaf

    ///
    /// A tree node consists of a color, left subtree, key, value and right subtree.
    ///
    case Node(Color, RedBlackTree[k, v], k, v, RedBlackTree[k, v])

  }

  ///
  /// The color of a red-black tree node.
  ///
  pub enum Color {

    case Red
    case Black

    ///
    /// The special color double-black is allowed temporarily during deletion.
    ///
    case DoubleBlack

  }

  ///
  /// Returns the number of nodes in `tree`.
  ///
  pub def size(tree: RedBlackTree[k, v]): Int32 = match tree {
    case Node(_, a, _, _, b) => 1 + size(a) + size(b)
    case _ => 0
  }

  ///
  /// Returns the empty tree.
  ///
  pub def empty(): RedBlackTree[k, v] = Leaf

  ///
  /// Updates `tree` with `k -> v` if `k -> v1` is in `tree`.
  ///
  /// Otherwise, updates `tree` with `k -> v`.
  ///
  pub def insert(k: k, v: v, tree: RedBlackTree[k, v]): RedBlackTree[k, v] =
    insertWith((_, v1, _) -> v1, k, v, tree)

  ///
  /// Updates `tree` with `k -> f(k, v, v1)` if `k -> v1` is in `tree`.
  ///
  /// Otherwise, updates `tree` with `k -> v`.
  ///
  pub def insertWith(f: (k, v, v) -> v & e, k: k, v: v, tree: RedBlackTree[k, v]): RedBlackTree[k, v] & e =
    blacken(insertWithHelper(f, k, v, tree))

  ///
  /// Updates `tree` with `k -> v1` if `k -> v` is in `tree` and `f(k, v) = Some(v1)`.
  ///
  /// Otherwise, returns `tree`.
  ///
  pub def updateWith(f: (k, v) -> Option[v] & e, k: k, tree: RedBlackTree[k, v]): RedBlackTree[k, v] & e =
    blacken(updateWithHelper(f, k, tree))

  ///
  /// Removes `k -> v` from `tree` if `tree` contains the key `k`.
  ///
  /// Otherwise, returns `tree`.
  ///
  pub def delete(k: k, tree: RedBlackTree[k, v]): RedBlackTree[k, v] = redden(deleteHelper(k, tree))

  ///
  /// Returns `Some(v)` if `k -> v` is in `tree`.
  ///
  /// Otherwise returns `None`.
  ///
  pub def get(k: k, tree: RedBlackTree[k, v]): Option[v] = match tree {
    case Node(_, a, k1, v, b) =>
      let cmp = k <=> k1;
      if (cmp < 0)
        get(k, a)
      else if (cmp == 0)
        Some(v)
      else
        get(k, b)
    case _ => None
  }

  ///
  /// Returns `true` if and only if `tree` contains the key `k`.
  ///
  pub def memberOf(k: k, tree: RedBlackTree[k, v]): Bool = get(k, tree) != None

  ///
  /// Optionally returns the first key-value pair in `tree` that satisfies the predicate `f` when searching from left to right.
  ///
  /// The function `f` must be pure.
  ///
  pub def findLeft(f: (k, v) -> Bool, tree: RedBlackTree[k, v]): Option[(k, v)] = match tree {
    case Node(_, a, k, v, b) => match findLeft(f, a) {
      case None => if (f(k, v)) Some((k, v)) else findLeft(f, b)
      case Some((k1, v1)) => Some((k1, v1))
    }
    case _ => None
  }

  ///
  /// Optionally returns the first key-value pair in `tree` that satisfies the predicate `f` when searching from right to left.
  ///
  /// The function `f` must be pure.
  ///
  pub def findRight(f: (k, v) -> Bool, tree: RedBlackTree[k, v]): Option[(k, v)] = match tree {
    case Node(_, a, k, v, b) => match findRight(f, b) {
      case None => if (f(k, v)) Some(k, v) else findRight(f, a)
      case Some((k1, v1)) => Some((k1, v1))
    }
    case _ => None
  }

  ///
  /// Applies `f` to a start value `s` and all key-value pairs in `tree` going from left to right.
  ///
  /// That is, the result is of the form: `f(...f(f(s, k1, v1), k2, v2)..., vn)`.
  ///
  pub def foldLeft(f: (b, k, v) -> b & e, s: b, tree: RedBlackTree[k, v]): b & e = match tree {
    case Node(_, a, k, v, b) => foldLeft(f, f(foldLeft(f, s, a), k, v), b)
    case _ => s
  }

  ///
  /// Applies `f` to a start value `s` and all key-value pairs in `tree` going from right to left.
  ///
  /// That is, the result is of the form: `f(k1, v1, ...f(kn-1, vn-1, f(kn, vn, s)))`.
  ///
  pub def foldRight(f: (k, v, b) -> b & e, s: b, tree: RedBlackTree[k, v]): b & e = match tree {
    case Node(_, a, k, v, b) => foldRight(f, f(k, v, foldRight(f, s, b)), a)
    case _ => s
  }

  ///
  /// Applies `f` to all key-value pairs in `tree` going from left to right until a single pair `(k, v)` is obtained.
  ///
  /// That is, the result is of the form: `Some(f(...f(f(k1, v1, k2, v2), k3, v3)..., kn, vn))`
  ///
  /// Returns `None` if `tree` is the empty tree.
  ///
  pub def reduceLeft(f: (k, v, k, v) -> (k, v) & e, tree: RedBlackTree[k, v]): Option[(k, v)] & e =
    reduceLeftHelper((x: Option[(k, v)], y: (k, v)) -> match x {
      case Some((k, v)) => Some(f(k, v, fst(y), snd(y)))
      case None => Some(y)
    }, None, tree)

  ///
  /// Applies `f` to all key-value pairs in `tree` going from right to left until a single pair `(k, v)` is obtained.
  ///
  /// That is, the result is of the form: `Some(f(k1, v1, ...f(kn-2, vn-2, f(kn-1, vn-1, kn, vn))...))`.
  ///
  /// Returns `None` if `tree` is the empty tree.
  ///
  pub def reduceRight(f: (k, v, k, v) -> (k, v) & e, tree: RedBlackTree[k, v]): Option[(k, v)] & e =
    reduceRightHelper((x: Option[(k, v)], y: (k, v)) -> match x {
      case Some((k, v)) => Some(f(fst(y), snd(y), k, v))
      case None => Some(y)
    }, None, tree)

  ///
  /// Returns `true` if and only if at least one key-value pair in `tree` satisfies the predicate `f`.
  ///
  /// Returns `false` if `tree` is the empty tree.
  ///
  /// The function `f` must be pure.
  ///
  pub def exists(f: (k, v) -> Bool, tree: RedBlackTree[k, v]): Bool = match tree {
    case Node(_, a, k, v, b) => f(k, v) || exists(f, a) || exists(f, b)
    case _ => false
  }

  ///
  /// Returns `true` if and only if all key-value pairs in `tree` satisfy the predicate `f`.
  ///
  /// Returns `true` if `tree` is the empty tree.
  ///
  /// The function `f` must be pure.
  ///
  pub def forall(f: (k, v) -> Bool, tree: RedBlackTree[k, v]): Bool = match tree {
    case Node(_, a, k, v, b) => f(k, v) && forall(f, a) && forall(f, b)
    case _ => true
  }

  ///
  /// Applies `f` to every key-value pair of `tree`.
  ///
  /// The function `f` must be impure.
  ///
  pub def foreach(f: (k, v) ~> Unit, tree: RedBlackTree[k, v]): Unit & Impure = match tree {
    case Node(_, a, k, v, b) => foreach(f, a); f(k, v); foreach(f, b)
    case _ => ()
  }

  ///
  /// Helper function for `insert` and `delete`.
  ///
  def balance(tree: RedBlackTree[k, v]): RedBlackTree[k, v] = match tree {
    case Node(Black, Node(Red, Node(Red, a, k1, v1, b), k2, v2, c), k3, v3, d) =>
      Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case Node(Black, Node(Red, a, k1, v1, Node(Red, b, k2, v2, c)), k3, v3, d) =>
      Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case Node(Black, a, k1, v1, Node(Red, Node(Red, b, k2, v2, c), k3, v3, d)) =>
      Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case Node(Black, a, k1, v1, Node(Red, b, k2, v2, Node(Red, c, k3, v3, d))) =>
      Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case Node(DoubleBlack, a, k1, v1, Node(Red, Node(Red, b, k2, v2, c), k3, v3, d)) =>
      Node(Black, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case Node(DoubleBlack, Node(Red, a, k1, v1, Node(Red, b, k2, v2, c)), k3, v3, d) =>
      Node(Black, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case _ => tree
  }

  ///
  /// Helper function for `insert`.
  ///
  def blacken(tree: RedBlackTree[k, v]): RedBlackTree[k, v] = match tree {
    case Node(Red, Node(Red, a, k1, v1, b), k2, v2, c) =>
      Node(Black, Node(Red, a, k1, v1, b), k2, v2, c)
    case Node(Red, a, k1, v1, Node(Red, b, k2, v2, c)) =>
      Node(Black, a, k1, v1, Node(Red, b, k2, v2, c))
    case _ => tree
  }

  ///
  /// Helper function for `insertWith`.
  ///
  def insertWithHelper(f: (k, v, v) -> v & e, k: k, v: v, tree: RedBlackTree[k, v]): RedBlackTree[k, v] & e = match tree {
    case Leaf => Node(Red, Leaf, k, v, Leaf)
    case Node(color, a, k1, v1, b) =>
      let cmp = k <=> k1;
      if (cmp < 0)
        balance(Node(color, insertWithHelper(f, k, v, a), k1, v1, b))
      else if (cmp == 0)
        Node(color, a, k, f(k, v, v1), b)
      else
        balance(Node(color, a, k1, v1, insertWithHelper(f, k, v, b)))
    case _ => tree
  }

  ///
  /// Helper function for `updateWith`.
  ///
  def updateWithHelper(f: (k, v) -> Option[v] & e, k: k, tree: RedBlackTree[k, v]): RedBlackTree[k, v] & e = match tree {
    case Leaf => tree
    case Node(color, a, k1, v1, b) =>
      let cmp = k <=> k1;
      if (cmp < 0)
        balance(Node(color, updateWithHelper(f, k, a), k1, v1, b))
      else if (cmp == 0)
        match f(k1, v1) {
          case None => tree
          case Some(v) => Node(color, a, k, v, b)
        }
      else
        balance(Node(color, a, k1, v1, updateWithHelper(f, k, b)))
    case _ => tree
  }

  ///
  /// Helper function for `delete`.
  ///
  def rotate(tree: RedBlackTree[k, v]): RedBlackTree[k, v] = match tree {
    case Node(Red, Node(DoubleBlack, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d)) =>
      balance(Node(Black, Node(Red, Node(Black, a, k1, v1, b), k2, v2, c), k3, v3, d))
    case Node(Red, DoubleBlackLeaf, k2, v2, Node(Black, c, k3, v3, d)) =>
      balance(Node(Black, Node(Red, Leaf, k2, v2, c), k3, v3, d))
    case Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(DoubleBlack, c, k3, v3, d)) =>
      balance(Node(Black, a, k1, v1, Node(Red, b, k2, v2, Node(Black, c, k3, v3, d))))
    case Node(Red, Node(Black, a, k1, v1, b), k2, v2, DoubleBlackLeaf) =>
      balance(Node(Black, a, k1, v1, Node(Red, b, k2, v2, Leaf)))
    case Node(Black, Node(DoubleBlack, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d)) =>
      balance(Node(DoubleBlack, Node(Red, Node(Black, a, k1, v1, b), k2, v2, c), k3, v3, d))
    case Node(Black, DoubleBlackLeaf, k2, v2, Node(Black, c, k3, v3, d)) =>
      balance(Node(DoubleBlack, Node(Red, Leaf, k2, v2, c), k3, v3, d))
    case Node(Black, Node(Black, a, k1, v1, b), k2, v2, Node(DoubleBlack, c, k3, v3, d)) =>
      balance(Node(DoubleBlack, a, k1, v1, Node(Red, b, k2, v2, Node(Black, c, k3, v3, d))))
    case Node(Black, Node(Black, a, k1, v1, b), k2, v2, DoubleBlackLeaf) =>
      balance(Node(DoubleBlack, a, k1, v1, Node(Red, b, k2, v2, Leaf)))
    case Node(Black, Node(DoubleBlack, a, k4, v4, b), k1, v1, Node(Red, Node(Black, c, k2, v2, d), k3, v3, e)) =>
      Node(Black, balance(Node(Black, Node(Red, Node(Black, a, k4, v4, b), k1, v1, c), k2, v2, d)), k3, v3, e)
    case Node(Black, DoubleBlackLeaf, k1, v1, Node(Red, Node(Black, c, k2, v2, d), k3, v3, e)) =>
      Node(Black, balance(Node(Black, Node(Red, Leaf, k1, v1, c), k2, v2, d)), k3, v3, e)
    case Node(Black, Node(Red, a, k4, v4, Node(Black, b, k1, v1, c)), k2, v2, Node(DoubleBlack, d, k3, v3, e)) =>
      Node(Black, a, k4, v4, balance(Node(Black, b, k1, v1, Node(Red, c, k2, v2, Node(Black, d, k3, v3, e)))))
    case Node(Black, Node(Red, a, k4, v4, Node(Black, b, k1, v1, c)), k2, v2, DoubleBlackLeaf) =>
      Node(Black, a, k4, v4, balance(Node(Black, b, k1, v1, Node(Red, c, k2, v2, Leaf))))
    case _ => tree
  }

  ///
  /// Helper function for `delete`.
  ///
  def redden(tree: RedBlackTree[k, v]): RedBlackTree[k, v] = match tree {
    case Node(Black, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d)) =>
      Node(Red, Node(Black, a, k1, v1, b), k2, v2, Node(Black, c, k3, v3, d))
    case DoubleBlackLeaf => Leaf
    case _ => tree
  }

  ///
  /// Helper function for `delete`.
  ///
  def minDelete(tree: RedBlackTree[k, v]): (k, v, RedBlackTree[k, v]) = match tree {
    case Node(Red, Leaf, k1, v1, Leaf) => (k1, v1, Leaf)
    case Node(Black, Leaf, k1, v1, Leaf) => (k1, v1, DoubleBlackLeaf)
    case Node(Black, Leaf, k1, v1, Node(Red, Leaf, k2, v2, Leaf)) =>
      (k1, v1, Node(Black, Leaf, k2, v2, Leaf))
    case Node(c, a, k1, v1, b) =>
      let (k3, v3, e) = minDelete(a);
      (k3, v3, rotate(Node(c, e, k1, v1, b)))
    case _ => panic "impossible"
  }

  ///
  /// Helper function for `delete`.
  ///
  def deleteHelper(k: k, tree: RedBlackTree[k, v]): RedBlackTree[k, v] = match tree {
    case Node(Red, Leaf, k1, _, Leaf) => if (k <=> k1 == 0) Leaf else tree
    case Node(Black, Leaf, k1, _, Leaf) => if (k <=> k1 == 0) DoubleBlackLeaf else tree
    case Node(Black, Node(Red, Leaf, k1, v1, Leaf), k2, v2, Leaf) =>
      let cmp = k <=> k2;
      if (cmp < 0)
        Node(Black, deleteHelper(k, Node(Red, Leaf, k1, v1, Leaf)), k2, v2, Leaf)
      else if
        (cmp == 0) Node(Black, Leaf, k1, v1, Leaf)
      else
        Node(Black, Node(Red, Leaf, k1, v1, Leaf), k2, v2, Leaf)
    case Node(c, a, k1, v1, b) =>
      let cmp = k <=> k1;
      if (cmp < 0)
        rotate(Node(c, deleteHelper(k, a), k1, v1, b))
      else if (cmp == 0)
        let (k2, v2, e) = minDelete(b);
        rotate(Node(c, a, k2, v2, e))
      else
        rotate(Node(c, a, k1, v1, deleteHelper(k, b)))
    case _ => tree
  }

  ///
  /// Helper function for `reduceLeft`.
  ///
  def reduceLeftHelper(f: (Option[(k, v)], (k, v)) -> Option[(k, v)] & e, s: Option[(k, v)], tree: RedBlackTree[k, v]): Option[(k, v)] & e =
    match tree {
      case Node(_, a, k, v, b) => reduceLeftHelper(f, f(reduceLeftHelper(f, s, a), (k, v)), b)
      case _ => s
    }

  ///
  /// Helper function for `reduceRight`.
  ///
  def reduceRightHelper(f: (Option[(k, v)], (k, v)) -> Option[(k, v)] & e, s: Option[(k, v)], tree: RedBlackTree[k, v]): Option[(k, v)] & e =
    match tree {
      case Node(_, a, k, v, b) => reduceRightHelper(f, f(reduceRightHelper(f, s, b), (k, v)), a)
      case _ => s
    }

}