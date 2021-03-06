//
//  CoordinateExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation
import MapKit

fileprivate let x_pi = Double.pi * 3000.0 / 180.0

public extension CLLocationCoordinate2D {
    init(baidu coord: CLLocationCoordinate2D) {
        let x = coord.longitude - 0.0065, y = coord.latitude - 0.006
        let z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) - 0.000003 * cos(x * x_pi)
        let lon = z * cos(theta)
        let lat = z * sin(theta)
        self.init(latitude: lat, longitude: lon)
    }

    var baidu: CLLocationCoordinate2D {
        let x = longitude, y = latitude
        let z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) + 0.000003 * cos(x * x_pi)
        let lon = z * cos(theta) + 0.0065
        let lat = z * sin(theta) + 0.006
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func distance(from coord: CLLocationCoordinate2D, isBaidu: Bool = false) -> Double {
        let coord1 = isBaidu ? CLLocationCoordinate2D(baidu: self) : self
        let coord2 = isBaidu ? CLLocationCoordinate2D(baidu: coord) : coord
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return loc1.distance(from: loc2)
    }
}
