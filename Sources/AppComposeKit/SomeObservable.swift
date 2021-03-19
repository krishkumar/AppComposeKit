//
//  SomeObservable.swift
//  AppComposeKit
//
//  Created by Krishna Kumar on 5/30/21.
//

import Foundation
import SwiftUI
import Combine

public class SomeObservable: ObservableObject {

    @Published public var information: String = "" // Will be automagically consumed by `Views`.

    public let updatePublisher = PassthroughSubject<Void, Never>() // Can be consumed by other classes / objects.

    // Added here only to test the whole thing.
    var someObserverClass: SomeObserverClass?

    public init() {
        // Randomly change the information each second.
        Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateInformation),
            userInfo: nil,
            repeats: true
        ).fire()    }

    @objc public func updateInformation() {
        // For testing purposes only.
        if someObserverClass == nil { someObserverClass = SomeObserverClass(observable: self) }

        // `Views` will detect this right away.
        information = String("RANDOM_INFO".shuffled().prefix(5))

        // "Manually" sending updates, so other classes / objects can be notified.
        updatePublisher.send()
    }
}

public class SomeObserverClass {

    @ObservedObject var observable: SomeObservable

    // More on AnyCancellable on: apple-reference-documentation://hs-NDfw7su
    var cancellable: AnyCancellable?

    public init(observable: SomeObservable) {
        self.observable = observable

        // `sink`: Attaches a subscriber with closure-based behavior.
        cancellable = observable.updatePublisher
            .print() // Prints all publishing events.
            .sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.doSomethingWhenObservableChanges()
        })
    }

    func doSomethingWhenObservableChanges() {
        print(observable.information)
    }
}

//let observable = SomeObservable()

public struct SomeObserverView: View {
    @ObservedObject var observable: SomeObservable
    public init(observable:SomeObservable) {
        self.observable = observable
    }
    public var body: some View {
        Text(observable.information)
    }
}
