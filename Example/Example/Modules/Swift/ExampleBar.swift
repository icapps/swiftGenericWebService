import Faro

class ExampleBar: Bar {

    init() {
        super.init(service: JSONService(configuration: Configuration(baseURL: "http://jsonplaceholder.typicode.com")))
    }

    override func serve<M: Mappable>(order: Order, result: (Result<M>) -> ()) {
        super.serve(order, result: result)
    }

}