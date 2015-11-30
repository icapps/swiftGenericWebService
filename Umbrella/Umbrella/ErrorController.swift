//
//  BaseModelError.swift
//  Umbrella
//
//  Created by Stijn Willems on 29/11/15.
//  Copyright © 2015 dooz. All rights reserved.
//

import Foundation

/**
* This class is responsible to handle errors in general and in a type specific way.
*/

public protocol ErrorController
{
	init()
	func requestBodyError() throws -> ()
}

public enum RequestError: ErrorType {
	case InvalidBody
}