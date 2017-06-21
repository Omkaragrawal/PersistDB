import Foundation
import Radicle
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: Schemata.Model> {
    /// Test whether the predicate evaluates to true for the given model.
    public let evaluate: (Model) -> Bool
    
    public let sqlExpression: Expression<Bool>
    
    fileprivate init(
        evaluate: @escaping (Model) -> Bool,
        sqlExpression: Expression<Bool>
    ) {
        self.evaluate = evaluate
        self.sqlExpression = sqlExpression
    }
}

extension Predicate: Hashable {
    public var hashValue: Int {
        return 0
    }
    
    public static func ==(lhs: Predicate, rhs: Predicate) -> Bool {
        return true
    }
}

/// Test whether a property of the model matches a value.
public func ==<Model>(lhs: KeyPath<Model, String>, rhs: String) -> Predicate<Model> {
    let sqlExpression = Model.schema
        .properties(for: lhs)
        .map { property -> Expression<Bool> in
            let lhsTable = Table(String(describing: property.model))
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                return lhsTable[property.path] as Expression<Any> == Table(String(describing: model))["id"]
            case .value:
                return lhsTable[property.path] as Expression<String> == rhs
            }
        }
        .reduce(nil) { result, expression -> Expression<Bool> in
            return result.map { $0 && expression } ?? expression
        }!
    
    return Predicate<Model>(
        evaluate: { $0[keyPath: lhs] == rhs },
        sqlExpression: sqlExpression
    )
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        fatalError()
    }
}
