/*
 Matrix.swift
 MatrixTest

 Created by Brandon Zimmerman on 12/14/17.

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published
 by the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 `Matrix` is a versatile, abstract data type that serves as a two-dimensional collection of elements, with methods for accessing and manipulating its data in various ways. Matrices use zero-indexed row and column indices to access its elements.
 */
/*
 There are two implementation details of Matrix that are deliberately hidden to simplify its API: the `size` property and corresponding `Size` class (neither of which are relevant to the user of Matrix); and the `elements` array property, which is the underlying storage structure of the Matrix's elements. This particular detail is abstracted away by making most interactions with the Matrix require using row-and-column coordinate pairs, since this is a more natural way to interact with a matrix, in general. There are two methods that expose the flat underlying nature of the data, and that is `subscript(i:)` (provided for convenience), and the `flattened` computed property, which simply returns the underlying array, but does so exposing a more descriptive name.
 */
struct Matrix<Element> {
    private var elements: [Element] // This implementation is not directly exposed by this name; access via `flattened`
    private let size: Size // This implementation is not exposed; access dimensions via `height` and `width` properties below
    /**
     The number of rows in the matrix.
     **/
    var height: Int { return size.height }
    /**
     The number of columns in the matrix.
     **/
    var width: Int { return size.width }
    /**
     The elements of the matrix, flattened into a single array.
     **/
    var flattened: [Element] { return elements }
    /**
     Creates a new `Matrix` from a `Collection` type.
     - Precondition: The count of the collection must be equal to product of the height and width parameters.
     - Parameters:
        - height: The height of the matrix.
        - width: The width of the matrix.
        - elements: A collection of elements, where the row is the major axis (i.e. elements of a common row will be contiguous in the collection, whereas elements of a common column will not be). The only constraint is that `elements` must by a `Collection` type.
     */
    init<C: Collection>(height: Int, width: Int, elements: C) where C.Element == Element {
        let size = Size(height: height, width: width)
        precondition(elements.count == size.count,
                     "There must be exactly \(size.count) elements to construct a(n) \(size) matrix")
        self.size = size
        self.elements = elements.map { $0 }
    }
    /**
     Creates a new `Matrix` from a nested `Collection` type.
     - Precondition: The total number of elements in the collection must be equal to product of the height and width parameters.
     - Parameters:
        - height: The height of the matrix.
        - width: The width of the matrix.
        - elements: A nested (two-dimensional) collection of elements, grouped by row. The only constraint is that `elements` must by a `Collection` type containing any other `Collection` type.
     */
    init<C: Collection>(height: Int, width: Int, elements: C) where C.Element: Collection, C.Element.Element == Element {
        self.init(height: height, width: width, elements: elements.flatMap { $0 })
    }
    /**
     Creates a new `Matrix` that will be inhabited by a single, repeated value.
     - Parameters:
        - height: The height of the matrix.
        - width: The width of the matrix.
        - repeating: A value with which to populate the entire matrix.
     */
    init(height: Int, width: Int, repeating: Element) {
        size = Size(height: height, width: width)
        elements = Array(repeating: repeating, count: size.count)
    }
    /**
     Creates a new `Matrix` that will be populated by a closure supplied by the caller.
     - Parameters:
        - height: The height of the matrix.
        - width: The width of the matrix.
        - dataSource: A closure which takes a `(row: Int, column: Int)` tuple as its only argument (corresponding to coordinates of a cell in the matrix), and returns the element that should be inserted into the matrix at those coordinates. This function may throw if desired.
     */
    init(height: Int, width: Int, dataSource: (_ coordinates: (row: Int, column: Int)) throws -> Element) rethrows {
        size = Size(height: height, width: width)
        elements = try size.map { coordinates in
            try dataSource(coordinates)
        }
    }
    /**
     Repopulates the matrix with new elements, using a closure supplied by the caller.
     - Parameters:
        - dataSource: A closure which takes a `(row: Int, column: Int)` tuple as its only argument (corresponding to coordinates of a cell in the matrix), and returns the element that should be inserted into the matrix at those coordinates. This function may throw if desired.
     */
    mutating func repopulate(_ dataSource: (_ coordinates: (row: Int, column: Int)) throws -> Element) rethrows {
        elements = try size.map { coordinates in
            try dataSource(coordinates)
        }
    }
    /**
     Calls the given closure for each cell in the matrix, supplying the coordinates of the cell as well as the element in the cell.
     - Parameters:
        - body: A closure which takes a `(row: Int, column: Int)` tuple as its first argument (corresponding to coordinates of an element in the matrix), and the `Element` at those coordinates as its second argument.
     */
    func forEachCell(body: ((row: Int, column: Int), Element) throws -> ()) rethrows {
        for position in size {
            try body(position, self[position.row, position.column])
        }
    }
    /**
     Returns an array of elements corresponding to a row in the matrix.
     - Precondition: `n` must be from 0 up to (but not including) the height of the array.
     - Parameters:
        - n: The row number, zero-indexed.
     */
    func row(_ n: Int) -> [Element] {
        precondition(0 <= n && n < height, "Row does not exist")
        return Array(self[n * width ..< n * width + width])
    }
    /**
     Returns an array of elements corresponding to a column in the matrix.
     - Precondition: `n` must be from 0 up to (but not including) the width of the array.
     - Parameters:
        - n: The column number, zero-indexed.
     */
    func column(_ n: Int) -> [Element] {
        precondition(0 <= n && n < width, "Column does not exist")
        var column: [Element] = []
        for n in stride(from: n, to: elements.endIndex, by: width) {
            column.append(self[n])
        }
        return column
    }
    /**
     Returns a nested array of all of the elements in the matrix, sorted by rows.
     */
    func rows() -> [[Element]] {
        return (0 ..< height).map { row($0) }
    }
    /**
     Returns a nested array of all of the elements in the matrix, sorted by columns.
     */
    func columns() -> [[Element]] {
        return (0 ..< width).map { column($0) }
    }
}
// Conforming to Sequence
extension Matrix: Sequence {
    typealias Iterator = Array<Element>.Iterator
    func makeIterator() -> Iterator {
        return elements.makeIterator()
    }
    /**
     Returns a matrix of the same dimensions containing the results of mapping the given closure over the matrix's elements.
     - Parameters:
        - transform: A closure which takes an element of the matrix as its only argument, and returns an instance of some type `T`, which can be of any type.
     **/
    func map<T>(_ transform: (Element) throws -> T) rethrows -> Matrix<T> {
        let newElements = try elements.map(transform)
        return Matrix<T>(height: height, width: width, elements: newElements)
    }
}
// Conforming to Collection
extension Matrix: BidirectionalCollection {
    var startIndex: Int { return elements.startIndex }
    var endIndex: Int { return elements.endIndex }
    var count: Int { return size.count } // Prob unneeded. Both should be O(1), calculating via mult. vs subtr.
    func index(after i: Int) -> Int {
        return elements.index(after: i)
    }
    func index(before i: Int) -> Int {
        return elements.index(before: i)
    }
    /**
     Returns an element in the matrix, located using a flat index.
     - Precondition: The index must be from zero up to (but not including) the number of elements in the matrix.
     - Parameters:
        - i: A flat index into the matrix. This can also be thought of as a index into a flattened version of the matrix.
     **/
    subscript(i: Int) -> Element {
        get { return elements[i] }
        set { elements[i] = newValue }
    }
    /**
     Returns an element in the matrix, located at a specific row and column.
     - Precondition: The coordinate arguments must be within the bounds of the matrix.
     - Parameters:
        - row: The row that the element belongs to.
        - column: The column that the element belongs to.
     **/
    subscript(row: Int, column: Int) -> Element {
        get { return elements[row * width + column] }
        set { elements[row * width + column] = newValue }
    }
    /**
     Returns an element in the matrix, located at a specific row and column. Does the same thing as `subscript(row:column:)`, except returns `nil` if the coordinates are out-of-bounds.
     - Parameters:
        - row: The row that the element belongs to.
        - column: The column that the element belongs to.
     **/
    func element(row: Int, column: Int) -> Element? {
        guard (0 <= row && row < height) && (0 <= column && column < width) else {
            return nil
        }
        return self[row, column]
    }
}
// Math functions
extension Matrix {
    // Used for performing any numeric binary operation between two matrices
    /**
     Can be used to perform any element-for-element binary function between two matrices.
     - Precondition: The matrices must have the same dimensions.
     - Parameters:
        - lhs: The first matrix to use in the operation, whose elements will correspond to the first operand of the operation.
        - rhs: The second matrix to use in the operation, whose elements will correspond to the second operand of the operation.
        - operation: An operation (function) which takes a value from the first matrix as its first operand and a value from the second matrix as its second operand, and returns any value.
     - Note: The operation does not have to be homogenous. The first operand, second operand, and return type can each be of different types, but are not required to be (e.g. most math operations will be homogenous).
     **/
    static func operation<T, U, V>(lhs: Matrix<T>, rhs: Matrix<U>, operation: (T, U) -> V) -> Matrix<V> {
        precondition(lhs.size == rhs.size, "Matrices must have the same dimensions in order to perform any operations between them")
        let newElements: [V] = zip(lhs, rhs).map { pair in
            let (a, b) = pair
            return operation(a, b)
        }
        return Matrix<V>(height: lhs.height, width: lhs.width, elements: newElements)
    }
    /**
     Negates all numbers in the matrix.
     **/
    // Negating a matrix
    static prefix func - <T>(matrix: Matrix<T>) -> Matrix<T> where T: SignedNumeric {
        return matrix.map { -$0 }
    }
    /**
     Multiplies the matrix by a scalar value.
     **/
    static func * <T>(matrix: Matrix<T>, scalar: T) -> Matrix<T> where T: Numeric {
        return matrix.map { $0 * scalar }
    }
    /**
     Adds two matrices.
     **/
    static func + <T>(lhs: Matrix<T>, rhs: Matrix<T>) -> Matrix<T> where T: Numeric {
        return Matrix.operation(lhs: lhs, rhs: rhs, operation: +)
    }
    /**
     Subtracts two matrices.
     **/
    static func - <T>(lhs: Matrix<T>, rhs: Matrix<T>) -> Matrix<T> where T: Numeric {
        return Matrix.operation(lhs: lhs, rhs: rhs, operation: -)
    }
    /**
     Multiplies two matrices.
     **/
    static func * <T>(lhs: Matrix<T>, rhs: Matrix<T>) -> Matrix<T> where T: Numeric {
        return Matrix.operation(lhs: lhs, rhs: rhs, operation: *)
    }
    /**
     Divides two matrices.
     **/
    static func / <T>(lhs: Matrix<T>, rhs: Matrix<T>) -> Matrix<T> where T: FloatingPoint {
        return Matrix.operation(lhs: lhs, rhs: rhs, operation: /)
    }
}
// Equating
extension Matrix where Element: Equatable {
    /**
     Returns true if the matrices have the same dimensions and contains equal elements at corresponding coordinates.
     **/
    static func == (lhs: Matrix<Element>, rhs: Matrix<Element>) -> Bool {
        guard lhs.size == rhs.size else { return false }
        return lhs.elements == rhs.elements
    }
}



/**
 `MatrixConnectable` is a protocol which, when conformed to by an element stored in a `Matrix`, allows that object to be automatically connected by a reference to its neighboring elements in the matrix, by calling the method `connect()` on the `Matrix`.
 - Note: The four references must be `weak` references, to avoid having strong reference cycles between the elements.
 - Note: Due to the `Self` constraints on the references, `MatrixConnectable` can only be adopted by a class, since structs cannot contain properties of the same type as itself, and this would defeat the point of the referential nature of these properties, even so.
 */
protocol MatrixConnectable {
    var north: Self? { get set }
    var south: Self? { get set }
    var west: Self? { get set }
    var east: Self? { get set }
    var neighbors: Int { get }
}
extension MatrixConnectable {
    /**
     The total number of established connections to neighbors (i.e. the number of non-nil references to neighbors); between 0 and 4.
     **/
    var neighbors: Int {
        return (north == nil ? 0 : 1) + (south == nil ? 0 : 1) + (west == nil ? 0 : 1) + (east == nil ? 0 : 1)
    }
}
extension Matrix where Element: MatrixConnectable {
    /**
     Establishes connections to neighboring elements for all elements in the matrix.
     **/
    mutating func connect() {
        for position in size {
            var element = self[position.row, position.column]
            element.north = self.element(row: position.row - 1, column: position.column)
            element.south = self.element(row: position.row + 1, column: position.column)
            element.west = self.element(row: position.row, column: position.column - 1)
            element.east = self.element(row: position.row, column: position.column + 1)
        }
    }
}



// Size
// I chose not to document the methods of Size, as it is trivial and is only used internally by Matrix to handle coordinates-related logic and functionality
fileprivate struct Size {
    var height, width: Int
    init(height: Int, width: Int) {
        (self.height, self.width) = (height, width)
    }
    var count: Int { return height * width }
}
// Equatable
extension Size: Equatable {
    static func == (lhs: Size, rhs: Size) -> Bool {
        return (lhs.height == rhs.height && lhs.width == rhs.width)
    }
}
// Sequence; Size can be a sequence of coordinates that can be used by Matrix for populating itself iteratively with values from a data-source closure
extension Size: Sequence {
    func makeIterator() -> CoordinatesIterator {
        return CoordinatesIterator(height: height, width: width)
    }
    struct CoordinatesIterator: IteratorProtocol {
        let height, width: Int
        var row = 0, column = 0
        init(height: Int, width: Int) {
            (self.height, self.width) = (height, width)
        }
        mutating func next() -> (row: Int, column: Int)? {
            guard row != height else {
                return nil
            }
            let currentCoordinates = (row, column)
            column += 1
            if column == width {
                column = 0
                row += 1
            }
            return currentCoordinates
        }
    }
}


