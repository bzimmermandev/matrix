# Matrix

A Swift 4 `Matrix` value type that conforms to `Collection`. `Matrix` is a general-purpose alternative to using nested arrays to represent two-dimensional data. `Matrix` has a number of useful methods and properties for dealing with a matrix or matrices in a general-purpose or mathematical manner, and can easily be extended to provide custom functionality.

## Terminology

When I refer to a matrix's *cell*, I am referring to the concept of the container that holds each element. Inherent in each cell are its coordinates in the matrix, and the element that it holds. It is not an actual class, or anything that you should have to worry about.

## Creating a matrix

A matrix can be created in a number of ways. The easiest way is to create a matrix of repeating elements with `init(height:width:repeating:)`. Just note that if you pass in a reference type to this initializer, every element in the array will be a reference to the same object; if you want to initialize the matrix with separate instances of a reference type which are all initialized in the same way, see `init(height:width:dataSource:)` below.

```swift
var matrix = Matrix(height: 4, width: 4, repeating: 0) // Inferred to be of type Matrix<Int>
```

You can also create a matrix using the `init(height:width:dataSource:)` initializer. This initializer allows you to pass in a closure that does the work of initializing each cell of the matrix. The `dataSource` closure is of the type `((row: Int, column: Int)) throws -> Element`, where `Element` is the type that the matrix holds. This closure take as its only argument a tuple corresponding to the coordinate-pair of the cell that needs to be filled in. We can use this initializer if we want to intiailize the matrix in a more complex way using some populating logic.

We can use this initializer to easily create a times-table, for example:

```swift
var matrix = Matrix(height: 4, width: 4) { position -> Int in
    return (position.row + 1) * (position.column + 1)
}
```

Note that row and column indices are zero-indexed, and so need to be incremented in order to create a standard one-indexed times-table.

There is also an initializer for creating a matrix from any collection of the proper size:

```swift
var matrix = Matrix(height: 2, width: 3, elements: [4, 8, 15, 16, 23, 42])
```

And an initializer for creating a matrix from any nested collection of the proper size:

```swift
var matrix = Matrix(height: 2, width: 3, elements: [[4, 8, 15], [16, 23, 42]])
```

## Using your matrix

For the sake of example, we will assume we are working with the following matrix representing a times-table, making its second appearance in a more terse form:

```swift
var matrix = Matrix(height: 4, width: 4) { ($0.0 + 1) * ($0.1 + 1) }
```

### Repopulating the matrix

It is useful to know that a mutable matrix can be easily repopulated using cell coordinates, using the same kind of closure passed to the `init(height:width:dataSource:)` initializer.

```swift
matrix.repopulate { ($0.0 + 1) * ($0.1 + 1) } // Here, it effectively overwrites the matrix with the same exact data.
```

### Accessing and changing elements

Elements in a matrix can be accessed using subscript syntax by providing a row-column coordinate-pair:

```swift
matrix[1, 3] // 8 is at row 1, column 3
```

They can be changed using the same subscript syntax.

```swift
matrix[1, 3] = 8 // No change
```

### Dimensions of the matrix

Each matrix has `height` and `width` properties, representing the number of rows and columns in the matrix, respectively:

```swift
// Prints "The matrix is 4 rows by 4 columns"
print("The matrix is \(matrix.height) rows by \(matrix.width) columns")
```

### Flattening the matrix

Matrices also have a `flattened` property, which is the flattened (i.e. one-dimensional) version of the matrix, in the form of an `Array`.

```swift
matrix.flattened // [1, 2, 3, 4, 2, 4, 6, 8, 3, 6, 9, 12, 4, 8, 12, 16]
```

### Enumerating matrix cells

Matrix has a `forEachCell(body:)` method, which is very similar to `forEach(body:)`, except that it enumerates each coordinate-pair in addition to each element. As such, the `body` closure takes two arguments, the first being a 2-tuple of `Int`s corresponding the coordinate-pair of the cell, and the second being the element contained in the cell.

The following prints a listing of each cell in the matrix, including the coordinates and value of each cell.

```swift
matrix.forEachCell { position, product in
    print("\(position.row + 1) * \(position.column + 1) = \(product)")
}
```

Of course, `forEach(body:)` is still available for enumerating elements without their coordinates:

```swift
matrix.forEach { product in
    print(product)
}
```

*Or*, of course:

```swift
for product in matrix {
    print(product)
}
```

### Accessing rows and columns

There are also a few methods for dealing with indiviual rows and columns:

```swift
matrix.row(1) // [2, 4, 6, 8]
matrix.column(2) // [3, 6, 9, 12]
```

And methods for accessing all of the rows or columns:

```swift
// Due to the nature of times-tables, these two should both return the same value:
// [[1, 2, 3, 4], [2, 4, 6, 8], [3, 6, 9, 12], [4, 8, 12, 16]]
matrix.rows()
matrix.columns()
```

### Math operations

A number of math operators are overloaded for `Matrix`:
* Unary `-` negates a matrix of `SignedNumeric` elements
* `*` multiplies a matrix of `Numeric` elements by a single `Numeric` scalar value
* `+` adds two equally-sized matrices of `Numeric` elements
* `-` subtracts two equally-sized matrices of `Numeric` elements
* `*` mutliplies two equally-sized matrices of `Numeric` elements
* `/` divides two equally-sized matrices of `FloatingPoint` elements
* `==` equates two matrices (the matrices do not have to be the same size, but matrices of different sizes are always unequal).

There is also an `operation(lhs:rhs:operation:)` method, for applying any binary function/operation between two matrices. Interestingly, this is the type signature of the method:

`operation<T, U, V>(lhs: Matrix<T>, rhs: Matrix<U>, operation: (T, U) -> V) -> Matrix<V>`

As you can see, the operation does not *need* to be homogenous in its operands or return type, but can be if desired.

## `Sequence` and `Collection` conformance

`Matrix` conforms to both `Sequence` and `Collection`, specifically `BidirectionalCollection`. As such, all of the related methods are implemented for this type. The `Index` type is a single `Int`, a flat index into the matrix. You usually shouldn't have to worry about this implementation detail, and a separate (preferred) subscript method is provided for accessing elements in the matrix using row-and-column indices, as shown above under **Accessing and changing elements**.

There is also an overload of the `map(_:)` method that retains the `Matrix` structure.

## The `MatrixConnectable` protocol

`Matrix` also comes pre-packaged with a neat protocol called `MatrixConnectable`. `MatrixConnectable` is a protocol which, when conformed to by an element stored in a `Matrix`, allows that object to be automatically connected by a reference to its neighboring elements in the matrix, by calling the method `connect()` on the `Matrix`.

Here is the protocol definition:

```swift
protocol MatrixConnectable {
    var north: Self? { get set }
    var south: Self? { get set }
    var west: Self? { get set }
    var east: Self? { get set }
    var neighbors: Int { get }
}
```

There is a default implementation for the `neighbors` property. This property corresponds to the total number of connections to neighbors (i.e. the number of non-nil references to neighbors).

### Conforming

There are two caveats to be aware of when conforming to `MatrixConnectable`:

1. The four references must be `weak` references, to avoid having strong reference cycles between the elements.
2. Due to the `Self` constraints on the references, `MatrixConnectable` can only be adopted by a class, since structs cannot contain properties of the same type as itself, and this would defeat the point of the referential nature of these properties, even so.

With those in mind, this is how to conform your class to `MatrixConnectable`:

```swift
extension MyClass: MatrixConnectable {
    weak var north: MyClass?
    weak var south: MyClass?
    weak var west: MyClass?
    weak var east: MyClass?
}
```

Assuming that we have a mutable `Matrix<MyClass>` called `matrix`, we should be able to call `connect()`:

```swift
matrix.connect() // Will "connect" each element in the matrix to each of its neighbors.
```

In cases where cells (edge and corner) have no neighbors in some directions, some references will stay `nil`:

```swift
matrix[0, 0].north // nil
```

**Note**: If you are going to use this protocol with `Matrix`, make sure to call `connect()` after the matrix is modified in a way that warrants recalculating connections.
