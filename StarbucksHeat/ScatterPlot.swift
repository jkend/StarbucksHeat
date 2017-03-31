//
//  ScatterPlot.swift
//  StarbucksHeat
//
//  Created by Joy Kendall on 3/31/17.
//  Copyright © 2017 Joy. All rights reserved.
//

import Foundation
import MapKit

class ScatterPlot: NSObject, MKOverlay {
    // MARK: MKOverlay properties
    var boundingMapRect:MKMapRect
    var coordinate: CLLocationCoordinate2D
    
    // MARK: Instance variables
    var scatterPoints = [MKMapPoint]()
    
    // MARK: Initializer
    // Okay, yes, this should really just take an array of MKMapPoint, but at the moment
    // the parsing method creates HeatPoints - maybe I'll go back and deal with this later.
    init(with points:[HeatPoint]) {
        
        // Now find the bounding rectangle
        var upperLeft = points[0].mapPoint
        var lowerRight = upperLeft
        for heatPoint in points {
            let point = heatPoint.mapPoint
            if point.x < upperLeft.x {
                upperLeft.x = point.x
            }
            if point.y < upperLeft.y {
                upperLeft.y = point.y
            }
            if point.x > lowerRight.x {
                lowerRight.x = point.x
            }
            if point.y > lowerRight.y {
                lowerRight.y = point.y
            }
            
            scatterPoints.append(point)
        }
        let rectWidth = lowerRight.x - upperLeft.x
        let rectHeight = lowerRight.y - upperLeft.y
        boundingMapRect = MKMapRect(origin: upperLeft, size: MKMapSize(width: rectWidth, height: rectHeight))
        
        // Find the center of the map containing all these points, as a CLLocationCoordinate2D
        let centerMapPoint = MKMapPoint(x: upperLeft.x + (rectWidth/2), y: upperLeft.y + (rectHeight/2))
        coordinate = MKCoordinateForMapPoint(centerMapPoint)
        
        print("number found: \(scatterPoints.count)\n")
    }

    // MARK: Called by Overlay Renderer
    func scatterPointstIn(rect mapRect:MKMapRect, scale:MKZoomScale) -> [MKMapPoint] {
        var pointsInThisRect = [MKMapPoint]()
        
        for point in scatterPoints {
            if MKMapRectContainsPoint(mapRect, point) {

                
                
                pointsInThisRect.append(point)
            }
        }
        return pointsInThisRect
    }
    
}
