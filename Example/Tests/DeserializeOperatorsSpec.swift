import Quick
import Nimble
import Stella

import Faro
@testable import Faro_Example

class DeserializeOperatorsSpec: QuickSpec {

	override func spec() {
		describe("DeserializeOperatorsSpec") {

			context("Create from JSON") {


				context("Relations") {

					it("Single") {
						let randomNumber = "randomNumber"
						let json: [String: Any] = ["cellNumber": randomNumber, "foodTicket": "ticket"]

						var jail = Jail(from: ["": ""])

						jail <-> json

						expect(jail?.cellNumber) == randomNumber

					}

					it("Too many") {
						let json = [["uuid": "id1"], ["uuid": "id2"]] as Any?
						var animalArray: [Animal]?

						animalArray <-> json

						expect(animalArray?.count) == 2
					}
				}

				context("Primitive Types") {
					var json = [String: Any]()
					var o1: DeserializableObject!

					beforeEach {
						o1 = DeserializableObject()

						json[.uuid] = "some id"
						json[.amount] = 20
						json[.price] = 5.0
						json[.tapped] = true
						json[.date] = "1994-08-20"
					}

					it("Int") {
						o1.amount <-> json[.amount]

						expect(o1.amount) == json[.amount] as? Int
					}

					it("Double") {
						o1.price <-> json[.price]

						expect(o1?.price) == json[.price] as? Double
					}

					it("Bool") {
						o1?.tapped <-> json[.tapped]

						expect(o1?.tapped) == json[.tapped] as? Bool
					}

					it("String") {
						expect {
							try o1.uuid <-> json[.uuid]

							return expect(o1?.uuid) == json[.uuid] as? String
							}.toNot(throwError())
					}

					context("Date") {

						it("String in json") {
							o1.date <-> (json[.date], "yyyy-MM-dd")

							let formatter = DateFormatter()
							formatter.dateFormat = "yyyy-MM-dd"
							let currentDate = formatter.date(from: "1994-08-20")

							expect(o1.date) == currentDate

						}

						it("TimeInterval") {

							let anyTimeInterval: TimeInterval = 1234.0

							o1.date <-> anyTimeInterval

							let date = Date(timeIntervalSince1970: anyTimeInterval)
							expect(o1.date) == date
						}

						it("String") {
							o1.date <-> ("1994-08-20" as Any?, "yyyy-MM-dd")

							let formatter = DateFormatter()
							formatter.dateFormat = "yyyy-MM-dd"
							let currentDate = formatter.date(from: "1994-08-20")

							expect(o1.date) == currentDate
						}
					}
				}

			}

			context("Update form JSON") {
				var relation = [String: Any]()
				var json = [String: Any]()

				var parent: Parent!

				beforeEach {
					relation[.uuid] = "relation id"
					relation[.amount] = 20
					relation[.tapped] = true
					relation[.date] =  "1994-08-20"
					relation[.price] = 5.0

					json[.uuid] = "route id"
					json[.relation] = relation

					parent = Parent(from: json)
				}

				it("updates existing object") {

					expect(parent?.uuid) == "route id"
					expect(parent?.relation.uuid) == "relation id"
					expect(parent?.relation.amount) == 20
					expect(parent?.relation.price) == 5.0
					expect(parent?.relation.tapped) == true
					expect(parent?.relation.date).toNot(beNil())

					let initialRelation = parent?.relation
					try? parent?.update(from: json)

					expect(parent?.relation) === initialRelation
				}

				context("Too many") {

					var tooMany = [[String: Any]]()
					let allUUIDs = ["uuid 1", "uuid 2", "uuid 0"]

					beforeEach {
						tooMany.removeAll()
						for i in 0..<3 {
							relation["uuid"] = allUUIDs[i]
							tooMany.append(relation)
						}
						json["tooMany"] = tooMany

						try? parent.update(from: json)
					}

					it("has tooMany relation in JSON") {
						expect(json["tooMany"]).toNot(beNil())
					}

					it("has tooMany relation in Parent") {
						expect(parent.tooMany.map {$0.uuid}) == allUUIDs
					}

					context("Array relation") {

						it("updates") {
							//swiftlint:disable force_cast
							let originalTooMany = parent.tooMany

							var relationDifferentPrice = relation
							relationDifferentPrice["uuid"] = parent.tooMany[0].uuid
							relationDifferentPrice["price"] = (parent.tooMany[0].price ?? 0) + 100

							// remove original price from json
							json["tooMany"] = (json["tooMany"] as! [[String: Any]]).filter {($0["uuid"] as? String) != parent.tooMany[0].uuid}
							// set new price
							var jsonTooManyWithDifferentPrice = json["tooMany"] as? [[String: Any]]
							jsonTooManyWithDifferentPrice?.append(relationDifferentPrice)
							json["tooMany"] = jsonTooManyWithDifferentPrice

							expect((json["tooMany"] as? [[String: Any]])?.map {($0["price"] as? Double) ?? 0}) == [5.0, 5.0, 105.0]

							try? parent.update(from: json)

							expect(parent.tooMany[0]) === originalTooMany[0]
							expect(parent.tooMany[1]) === originalTooMany[1]
							expect(parent.tooMany[2]) === originalTooMany[2]

							expect(parent.tooMany.map {$0.uuid}) == [originalTooMany[0].uuid, originalTooMany[1].uuid, originalTooMany[2].uuid]
							expect(parent.tooMany.map {$0.price ?? 0}) == [105.0, 5.0, 5.0]

						}

						context("relation deserialize operator") {

							it("removes id's no longer in JSON") {
								//swiftlint:disable force_cast
								json["tooMany"] = (json["tooMany"] as! [[String: Any]]).filter {($0["uuid"] as? String) != "uuid 0"}

								try? parent.tooMany <-> json["tooMany"]

								expect(parent.tooMany.map {$0.uuid}) == ["uuid 2", "uuid 1"]
							}

							it("add id's in JSON") {
								let uuidAdded = "added id"
								relation["uuid"] = uuidAdded
								tooMany.append(relation)
								json["tooMany"] = tooMany

								let relations = json["tooMany"] as? [[String: Any]]

								var expected = allUUIDs
								expected.append(uuidAdded)

								expect(relations?.map {($0["uuid"] as? String) ?? ""}) == expected

								expect(parent.tooMany.map {$0.uuid}) == allUUIDs

								try? parent.tooMany <-> json["tooMany"]

								expect(parent.tooMany.map {$0.uuid}) == expected
							}

						}
					}

					context("Set relation") {

						var setTooMany = [[String: Any]]()
						var setRelation = [String: Any]()

						beforeEach {
								setRelation[.uuid] = "set id 1"
								setTooMany.append(setRelation)
								json[.setTooMany] = setTooMany

								try? parent.update(from: json)
						}

						it("has set too many") {
							expect(parent.setTooMany.map {$0.uuid}) == ["set id 1"]
						}

						it("updates") {
							//swiftlint:disable force_cast
							let originalTooMany = parent.setTooMany

							setRelation[.price] = 100.0
							json[.setTooMany] = [setRelation]

							expect((json[.setTooMany] as? [[String: Any]])?.map {($0[.price] as? Double) ?? 0}) == [0]
							expect((json[.setTooMany] as? [[String: Any]])?.map {($0[.uuid] as? String) ?? ""}) == ["set id 1"]

							try? parent.update(from: json)

							expect(parent.setTooMany.first) === originalTooMany.first

							expect(parent.setTooMany.map {$0.uuid}) == [originalTooMany.first!.uuid]
							expect(parent.setTooMany.map {$0.price ?? 0}) == [105.0, 5.0, 5.0]

						}

						xcontext("relation deserialize operator") {

							it("removes id's no longer in JSON") {
								//swiftlint:disable force_cast
								json["tooMany"] = (json["tooMany"] as! [[String: Any]]).filter {($0["uuid"] as? String) != "uuid 0"}

								try? parent.tooMany <-> json["tooMany"]

								expect(parent.tooMany.map {$0.uuid}) == ["uuid 1", "uuid 2"]
							}

							it("add id's in JSON") {
								let uuidAdded = "added id"
								relation["uuid"] = uuidAdded
								tooMany.append(relation)
								json["tooMany"] = tooMany

								let relations = json["tooMany"] as? [[String: Any]]

								var expected = allUUIDs
								expected.append(uuidAdded)

								expect(relations?.map {($0["uuid"] as? String) ?? ""}) == expected

								expect(parent.tooMany.map {$0.uuid}) == allUUIDs

								try? parent.tooMany <-> json["tooMany"]

								expect(parent.tooMany.map {$0.uuid}) == expected
							}

						}
					}

				}
			}
		}
	}

}

// MARK: - Example Models

class Parent: Deserializable, Updatable, Linkable {
	typealias ValueType = String

	var uuid: String
	var relation: DeserializableObject
	var tooMany = [DeserializableObject]()
	var setTooMany = Set<DeserializableObject>()

	// MARK: - Linkable

	var link: (key: String, value: String) { return (key: "uuid", value: uuid) }

	required init?(from raw: Any) {
		// Temp values are required because swift needs initialization
		uuid = ""
		relation = DeserializableObject()

		do {
			try update(from: raw)
		} catch {
			print(error)
			return nil
		}
	}

	func update(from raw: Any) throws {
		guard let json = raw as? [String: Any] else {
			throw FaroDeserializableError.wrongJSON(raw)
		}
		try uuid <-> json[.uuid]
		try relation <-> json[.relation]
		do {
			try tooMany <-> json[.tooMany]
			try setTooMany <-> json[.setTooMany]
		} catch {
			printError(error)
		}
	}

}
class DeserializableObject: Deserializable, Updatable, Linkable, Hashable, CustomDebugStringConvertible, CustomStringConvertible {
	typealias ValueType = String

	var uuid: String
	var amount: Int?
	var price: Double?
	var tapped: Bool?
	var date: Date?

	// MARK: - Hashable

	var hashValue: Int {
		return uuid.hashValue
	}

	static func == (lhs: DeserializableObject, rhs: DeserializableObject) -> Bool {
		return lhs.uuid == rhs.uuid
	}

	// MARK: - Linkable

	var link: (key: String, value: String) { return (key: "uuid", value: uuid) }

	convenience init () {
		self.init(from: ["uuid": UUID().uuidString])!
	}

	required init?(from raw: Any) {
		uuid = UUID().uuidString
		do {
			try update(from: raw)
		} catch {
			print(error)
			return nil
		}

	}

	func update(from raw: Any) throws {
		guard let json = raw as? [String: Any] else {
			throw FaroDeserializableError.wrongJSON(raw)
		}

		print("PRICE updating \(price) to \(json[.price] as? Double)")
		try self.uuid <-> json[.uuid]
		self.amount <-> json[.amount]
		self.price <-> json[.price]
		self.tapped <-> json[.tapped]
		self.date <-> (json[.date], "yyyy-MM-dd")
	}

	// MARK: - Custom String Convertible

	var description: String {return "DeserializableObject id: \(uuid) price: \(price)"}
	var debugDescription: String { return "DeserializableObject id: \(uuid) price: \(price), amount: \(amount), tapped: \(tapped), date: \(date)" }

}

// MARK: - Dictionary Helpers
enum API {

	enum Common: String {
		case uuid, amount, price, tapped, date
	}

	enum Relation: String {
		case tooMany, setTooMany, relation
	}
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {

	subscript (map: API.Common) -> Value? {
		get {
			guard let key = map.rawValue as? Key else {
				return nil
			}

			let dict = self[key] as Value?
			return dict

		} set (newValue) {
			guard let newValue = newValue, let key = map.rawValue as? Key  else {
				return
			}
			
			self[key] = newValue
		}
	}
	
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
	
	subscript (map: API.Relation) -> Value? {
		get {
			guard let key = map.rawValue as? Key else {
				return nil
			}
			
			let dict = self[key] as Value?
			return dict
			
		} set (newValue) {
			guard let newValue = newValue, let key = map.rawValue as? Key  else {
				return
			}
			
			self[key] = newValue
		}
	}
	
}
