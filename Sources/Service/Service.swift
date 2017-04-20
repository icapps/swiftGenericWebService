//
//  Service.swift
//  Pods
//
//  Created by Stijn Willems on 20/04/2017.
//
//

import Foundation

public enum Result<T> {
	case success(T)
	case fail(ServiceError)
}

public  enum ServiceError: Error {
	case fail(FaroError)
}

let json = [String: Any]()

/// We will always try to instantiate models using `JSONDeserializable`. 
/// `Deserializable` is for legacy reasons and will be removed in version 3.0
open class Service<T> where T: JSONDeserializable & Deserializable {

	private let deprecatedService: DeprecatedService
	private let call: Call
	private let autoStart: Bool

	public init(call: Call, autoStart: Bool = true, deprecatedService: DeprecatedService = FaroDeprecatedSingleton.shared) {
		self.deprecatedService = deprecatedService
		self.call = call
		self.autoStart = autoStart
	}

	// MARK: Requests that expect a JSON response

	open func single(complete: @escaping(@escaping () throws -> (T)) -> Void) {
		let call = self.call

		deprecatedService.performJsonResult(call, autoStart: autoStart) {[weak self] (result: DeprecatedResult<T>) in
			switch result {

			case .json(let json):
				let rootNode = call.rootNode(from: json)

				switch rootNode {
				case .nodeObject(let node):
					// Convert node to model of type T. When this is not possible an error is thrown.
					complete {try T(node)}
				default:
					complete { [weak self] in
						let error = FaroError.noModelFor(call: call, inJson: rootNode)
						self?.handleError(error)
						throw error
					}
				}
			case .failure(let error):
				complete { [weak self] in
					self?.handleError(error)
					throw error
				}
			default:
				complete { [weak self] in
					let error = FaroError.invalidDeprecatedResult(call: call, resultString: "\(result)")
					self?.handleError(error)
					throw error
				}
			}
		}
	}

	/// Converts every node in the json to T. When one of the nodes has invalid json conversion is stopped and an error is trhown.
	open func collection(complete: @escaping ( @escaping() throws -> [T]) -> Void)  {
		let call = self.call
		deprecatedService.performJsonResult(call, autoStart: autoStart) { [weak self] (result: DeprecatedResult<T>) in
			switch result {

			case .json(let json):
				let rootNode = call.rootNode(from: json)

				switch rootNode {
				case .nodeArray(let nodeArray):
					guard let nodeArray = nodeArray as? [[String: Any]] else {
						complete { [weak self] in
							let error = FaroError.noModelFor(call: call, inJson: rootNode)
							self?.handleError(error)
							throw error
						}
						return
					}

					// Convert every node to model of type T. When this is not possible an error is thrown.

					complete { try nodeArray.map {try T($0)} }
				default:
					complete { [weak self] in
						let error = FaroError.noModelFor(call: call, inJson: rootNode)
						self?.handleError(error)
						throw error
					}
				}
			case .failure(let error):
				complete { [weak self] in
					self?.handleError(error)
					throw error
				}
			default:
				complete { [weak self] in
					let error = FaroError.invalidDeprecatedResult(call: call, resultString: "\(result)")
					self?.handleError(error)
					throw error
				}
			}
		}
	}

	// MARK: Requests that expect no JSON in response

	// TODO: add write functions

	// MARK: Error

	/// Prints the error and throws it
	/// Possible to override this to have custom behaviour for your app.
	open func handleError(_ error: FaroError) {
		printFaroError(error)
	}

}
