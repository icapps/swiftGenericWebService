import Foundation
import Faro
import Stella

class Post: JSONDeserializable, Deserializable {
    let uuid: Int
    var title: String?

    enum DeprecatedServiceMap: String {
        case id, title
    }

	required init(_ raw: [String : Any]) throws {
		self.uuid = try create(Post.DeprecatedServiceMap.id.rawValue, from: raw)

		// Not required variables

		title |< raw[.title]
	}

    required init?(from raw: Any) {
        guard let json = raw as? [String: Any] else {
            return nil
        }
        do {
            self.uuid = try create(Post.DeprecatedServiceMap.id.rawValue, from: json)
        } catch {
            printError("Error parsing Post with \(error).")
            return nil
        }

        // Not required variables

        title |< json[.title]
    }

}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {

    subscript (map: Post.DeprecatedServiceMap) -> Value? {
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

func transform(_ map: [Post.DeprecatedServiceMap: Any]) -> [String: Any] {
    var result = [String: Any]()
    map.forEach { (dict:(key: Post.DeprecatedServiceMap, value: Any)) in
        result[dict.key.rawValue] = dict.value
    }
    return result
}
