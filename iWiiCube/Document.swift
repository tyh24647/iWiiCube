///
///  Document
///
///  Created by Tyler Hostager on 1/7/19.
///  Copyright © 2019 Tyler Hostager. All rights reserved.
///

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

