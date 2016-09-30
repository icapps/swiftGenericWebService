import Quick
import Nimble

import Faro
@testable import Faro_Example

class MockServiceSpec: QuickSpec {

    override func spec() {
        describe("MockService") {
            context("dictionary set") {
                var mockService: MockService!

                beforeEach {
                    mockService = MockService()
                }

                it("should return dictionary after perform") {
                    let uuid = "dictionary for testing"
                    mockService.mockDictionary = ["uuid": uuid]

                    mockService.perform(Call(path: "unit tests")) { (result: Result<MockModel>) in
                        switch result {
                        case .model( let model):
                            expect(model!.uuid) == uuid
                        default:
                            XCTFail("should provide a model")
                        }
                    }
                }
            }
        }
    }
    
}