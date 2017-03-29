//
//  HeatMap.swift
//  StarbucksHeat
//
//  Created by Joy Kendall on 3/28/17.
//  Copyright © 2017 Joy. All rights reserved.
//

import Foundation
import MapKit

class HeatMap: NSObject, MKOverlay {
    
    // MARK: MKOverlay protocol vars
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    var heatPoints: [HeatPoint]

    init(with heatPoints:[HeatPoint]) {
        self.heatPoints = heatPoints
        var upperLeft: MKMapPoint = self.heatPoints[0].mapPoint
        var lowerRight = upperLeft
        
        for hp in self.heatPoints {
            let coord = hp.mapPoint
            // Use it to find the upper left and lower right corners
            if coord.x < upperLeft.x {
                upperLeft.x = coord.x
            }
            if coord.y < upperLeft.y {
                upperLeft.y = coord.y
            }
            if coord.x > lowerRight.x {
                lowerRight.x = coord.x
            }
            if coord.y > lowerRight.y {
                lowerRight.y = coord.y
            }
        }
        let rectHeight = lowerRight.y - upperLeft.y
        let rectWidth = lowerRight.x - upperLeft.x
        boundingMapRect = MKMapRect(origin: upperLeft, size: MKMapSizeMake(rectWidth, rectHeight))
        let centerMapPoint = MKMapPointMake(upperLeft.x + (rectWidth/2), upperLeft.y + (rectHeight/2))
        coordinate = MKCoordinateForMapPoint(centerMapPoint)        
    }
    
    // These constants come from an article I read about Map zoom levels, by Troy Brant. It described
    // how zoom level 0 (all the way out) made a Mercator projection of the world with a single tile
    // of size 256x256, and each zoom level doubled each side but kept the tile size 256 - so by the
    // time we hit zoom level 20 (the maximum) each side was HUGE with more tiles than we'd care to count.
    private struct MapConstants {
        static let ZoomLevelZeroPoints = 256
        static let ZoomLevelTwentyPoints = 536870912
        static let MaxZoomLevel = 20
    }

}

struct HeatPoint {
    let mapPoint: MKMapPoint
    let heatValue: Int
}
