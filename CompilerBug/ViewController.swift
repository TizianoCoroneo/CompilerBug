//
//  ViewController.swift
//  CompilerBug
//
//  Created by Tiziano Coroneo on 01/07/2019.
//  Copyright © 2019 Tiziano Coroneo. All rights reserved.
//

import UIKit

protocol VIPERVC: UIViewController {
    associatedtype Interactor: VIPERInteractor
        where Interactor.Presenter.ViewController == Self
    
    static var storyboardName: String { get }
    static var storyboardIdentifier: String { get }
    
    var interactor: Interactor! { get set }
}

extension VIPERVC {
    typealias Presenter = Interactor.Presenter
}

protocol VIPERInteractor {
    associatedtype Presenter: VIPERPresenter
        where Presenter.ViewController.Interactor == Self
    
    init(_ repo: VIPEREntityRepository)
    
    var presenter: Presenter! { get set }
}

extension VIPERInteractor {
    typealias ViewController = Presenter.ViewController
}

protocol VIPERPresenter {
    associatedtype ViewController: VIPERVC
        where ViewController.Interactor.Presenter == Self
    
    init(_ vc: ViewController)
    
    var vc: ViewController! { get set }
}

extension VIPERPresenter {
    typealias Interactor = ViewController.Interactor
}

class TestEntity {
    func provideString() -> String {
        return "TestString"
    }
}

struct VIPEREntityRepository {
    private let testEntity = TestEntity()
    
    init() { }
    
    func provideEntity<T>() -> T {
        let mirror = Mirror(reflecting: self)
        guard let entity = mirror.children.first(where: { $0.value is T })
            else {
                let message = "Dependency with type: \(T.self) not found.\nAvailable dependencies:\n"
                let dependencies = mirror.children.map { "\($0.label ?? "nil"): \(type(of: $0.value))" }
                fatalError(message + dependencies.joined(separator: "\n")) }
        return entity.value as! T
    }
}

class TestViewController: UIViewController, VIPERVC {
    class var storyboardName: String { return "Main" }
    class var storyboardIdentifier: String { return "TestVC" }
    
    @IBOutlet var mainLabel: UILabel!
    
    typealias Interactor = TestInteractor
    
    var interactor: TestInteractor! = nil
    
    @IBAction func pressButton() {
        interactor.retrieveString()
    }
}

class TestInteractor: VIPERInteractor {
    typealias Presenter = TestPresenter
    
    var presenter: TestPresenter! = nil
    
    private let repo: VIPEREntityRepository
    private lazy var entity: TestEntity = repo.provideEntity()
    
    required init(_ repo: VIPEREntityRepository) {
        self.repo = repo
    }
    
    func retrieveString() {
        let string = entity.provideString()
        presenter.updateLabel(withString: string)
    }
}

class TestPresenter: VIPERPresenter {
    typealias ViewController = TestViewController
    
    required init(_ vc: ViewController) {
        self.vc = vc
    }
    
    unowned var vc: TestViewController!
    
    func updateLabel(withString str: String) {
        vc.mainLabel.text = str
    }
}

struct ModuleBuilder<VC: VIPERVC> {
    
    func build(_ repo: VIPEREntityRepository) -> VC {
        let storyboard = UIStoryboard(name: VC.storyboardName, bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: VC.storyboardIdentifier) as! VC
        
        var interactor = VC.Interactor(repo)
        var presenter = VC.Presenter(vc)
        
        vc.interactor = interactor
        interactor.presenter = presenter
        presenter.vc = vc
        
        return vc
    }
}
