import Foundation

private var ObservableUniqueID = (0...).makeIterator()
public let ObservableObserverQueue = DispatchQueue(label: "eventDispatchingQueue", attributes: .concurrent)

public final class Observable<T> {

    public typealias Observer = (T, T?) -> Void

    private var observers: [Int: Observer] = [:]
    private var uniqueID = (0...).makeIterator()
    
    private let queue: DispatchQueue

    public var value: T {
        didSet {
            let val = value
            let oval = oldValue
            
            queue.sync {
                observers.values.forEach { cb in ObservableObserverQueue.async { cb(val, oval) } }
            }
        }
    }

    public init(_ value: T) {
        self.value = value
        
        queue = DispatchQueue(label: "observable queue #\(ObservableUniqueID.next()!)", attributes: .concurrent)
    }

    public func observe(_ observer: @escaping Observer) -> Disposable {
        return observe(includingInitial: true, observer)
    }
    
    public func observe(includingInitial: Bool = true, _ observer: @escaping Observer) -> Disposable {
        guard let id = uniqueID.next() else { fatalError("There should always be a next unique id") }
        
        let disposable = Disposable { [weak self] in
            self?.observers[id] = nil
        }
        
        queue.async(flags: .barrier) {
            self.observers[id] = observer
        }
        
        if includingInitial {
            observer(self.value, nil)
        }
        
        return disposable
    }

    public func removeAllObservers() {
        observers.removeAll()
    }
}
