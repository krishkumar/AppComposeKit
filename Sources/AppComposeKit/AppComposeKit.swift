import Combine
import SwiftUI
import UIKit

// AppComposeKit
// kit for create fun apps

@available(iOS 13.0.0, *)
public struct ActivityIndicator: UIViewRepresentable {
    public func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    public func makeUIView(context: Context) -> some UIView {
        let a = UIActivityIndicatorView()
        a.startAnimating()
        return a
    }
    public init() { }
}


@available(iOS 13.0, *)
public class ValueFetcher<A> {
    @ObservedObject var remote: Remote<A>
    private var subscriptions = Set<AnyCancellable>()
    //var cancellable: AnyCancellable?
    @Published public var v:A?
    public init(remote: Remote<A>,  completion: @escaping (A?)->Void) {
        self.remote = remote
        self.remote.valuePublisher
            .print()
            .sink(receiveValue: { [weak self] v in
                guard let self = self else { return }
                self.v = v
                completion(v)
            })
            .store(in: &subscriptions)
        self.remote.load()
    }
}

@available(iOS 13.0, *)
public struct Loader<A, Placeholder, Content>:View where Placeholder:View, Content:View {
    private var subscriptions = Set<AnyCancellable>()
    public init(remote: Remote<A>, placeholder: Placeholder=ActivityIndicator() as! Placeholder, content: @escaping (A) -> Content) {
        self.placeholder = placeholder
        self.content = content
        self.remote = remote
        self.remote.updatePublisher
            .sink(receiveValue: { _ in
        })
            .store(in: &subscriptions)
    }
    
    @ObservedObject var remote: Remote<A>
    var placeholder: Placeholder
    var content: (A) -> Content
    public var body: some View {
        Group {
            if remote.value == nil {
                placeholder
            } else {
            content(remote.value!)
            }
        }
    }
}

@available(iOS 13.0, *)
public class Remote<A>:ObservableObject {
    let url: URLRequest
    @Published public var value: A? {
        didSet {
            self.subject.send()
            self.updatePublisher.send()
            if let v = value {
                self.valuePublisher.send(v)
            } else {
                self.valuePublisher.send(nil)
            }
        }
    }
    let parse: (Data) throws -> A
    public var objectWillChange: AnyPublisher<(),Never> = Publishers.Sequence(sequence: []).eraseToAnyPublisher()
    public var subject = PassthroughSubject<(),Never>()
    public let updatePublisher = PassthroughSubject<Void, Never>() // Can be consumed by other classes / objects.
    public let valuePublisher = PassthroughSubject<A?, Never>() // Can be consumed by other classes / objects.
    public init(url: URLRequest, parse: @escaping (Data) throws -> A) {
        self.url = url
        self.parse = parse
        self.objectWillChange = subject.handleEvents(receiveSubscription: { (_) in
            self.load()
        }).eraseToAnyPublisher()
    }
    public func load() {
        let configuration = URLSessionConfiguration.default
        // disable default credential store
        configuration.urlCredentialStorage = nil
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let d = data else {
                print("Data Error - \(self.url)")
                DispatchQueue.main.async {
                    self.value = nil
                }
                return
            }
            do {
                let result = try self.parse(d)
                DispatchQueue.main.async {
                    self.value = result
                }
            }
            catch {
                print(error)
                print(d.asDictionary)
                print(self.url.curlString)
                if let d = data, let s = String(data: d, encoding: String.Encoding.utf8) {
                    print(s)
                }
                DispatchQueue.main.async {
                    self.value = nil
                }                
            }
        }.resume()
    }
}

extension Encodable {
    var asDictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}

@available(iOS 13.0, *)
public extension Remote {
    convenience init(url:URL, parse: @escaping (Data)->A) {
        self.init(url: URLRequest(url: url), parse: parse)
    }
}

@available(iOS 13.0, *)
public extension Remote where A: Decodable {
    convenience init(url:URLRequest) {
        self.init(url: url) { data in
            try JSONDecoder().decode(A.self, from: data)
        }
    }
}

struct AppComposeKit {
    var text = "AppComposeKit"
}

@available(iOS 13.0, *)
public extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
