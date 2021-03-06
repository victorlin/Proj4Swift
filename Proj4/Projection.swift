//
//  Projection.swift
//  Proj4
//
//  Created by Fang-Pen Lin on 3/12/16.
//  Copyright © 2016 Fang-Pen Lin. All rights reserved.
//

import UIKit

import Proj4Lib

/**
    A Projection object provides coordinates transformation from one production to another
 */
public final class Projection {
    /// Double number for multiplying to convert from degree to radian
    public static let degToRad = DEG_TO_RAD
    /// Double number for multiplying to convert from radian to degree
    public static let radToDeg = RAD_TO_DEG
    
    public enum Error: ErrorType {
        /// Initialization failed
        case InitFailed(code: Int, message: String)
        /// Transform failed
        case TransformFailed(code: Int, message: String)
    }
    
    /// The General Parameters for proj4 configuration
    /// - See Also: [General Parameters](http://proj.maptools.org/gen_parms.html)
    public let parameters: String
    
    private let proj: UnsafeMutablePointer<Void>
    
    public init(parameters: String) throws {
        self.parameters = parameters
        proj = pj_init_plus(parameters)
        if proj == nil {
            throw Error.InitFailed(code: Int(errno), message: Projection.errorMessage())
        }
    }
    
    deinit {
        pj_free(proj)
    }
    
    public func transform(points: [Point3D], toProjection: Projection) throws -> [Point3D] {
        var xValues = points.map { $0.x }
        var yValues = points.map { $0.y }
        var zValues = points.map { $0.z }
        let retval = pj_transform(proj, toProjection.proj, points.count, 1, &xValues, &yValues, &zValues)
        if retval != 0 {
            throw Error.TransformFailed(code: Int(retval), message: Projection.errorMessage(retval))
        }
        return xValues.enumerate().map { index, x in
            return Point3D(x: x, y: yValues[index], z: zValues[index])
        }
    }
    
    private static func errorMessage(errno: Int32? = nil) -> String {
        var errno = errno
        if errno == nil {
            errno = pj_get_errno_ref().memory
        }
        let message = pj_strerrno(errno!)
        return String(UTF8String: UnsafePointer<CChar>(message))!
    }
}
