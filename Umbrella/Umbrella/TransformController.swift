
import Foundation


//Transformations of data to concrete objects.

public class TransfromController {
	
	public func objectDataToConcreteObject<ConcreteType: BaseModel>(data: NSData, completion:(ConcreteType)->()){
		
		let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
		completion(ConcreteType(json: json!))
		
	}
	
	public func objectsDataToConcreteObjects<ConcreteType: BaseModel>(data: NSData, completion:([ConcreteType])->()){
		
		let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
		
		if let array = json!["results"] as? [NSDictionary] {
			var concreteObjectArray = [ConcreteType]()
			for dict in array {
				concreteObjectArray.append(ConcreteType(json: dict))
			}
			completion(concreteObjectArray)
		}
	}
}