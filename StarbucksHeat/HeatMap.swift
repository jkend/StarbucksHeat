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
    
    private var heatPoints: [HeatPoint]
    private var maxValue = 0.0
    private var zoomedOutMaxValue = 0.0
    
    // These constants come from an article I read about Map zoom levels, by Troy Brant. It described
    // how zoom level 0 (all the way out) made a Mercator projection of the world with a single tile
    // of size 256x256, and each zoom level doubled each side but kept the tile size 256 - so by the
    // time we hit zoom level 20 (the maximum) each side was HUGE with more tiles than we'd care to count.
    private struct MapConstants {
        static let ZoomLevelZeroPoints = 256
        static let ZoomLevelTwentyPoints = 536870912
        static let ZoomLevels = 20
    }
    
    private struct ScalingConstants {
        static let ScalePower = 4.0;
        static let ScreenPointsPerBucket: CGFloat = 10;
    }
    
    
    // MARK: Initializer
    init(with heatPoints:[HeatPoint]) {
        self.heatPoints = heatPoints
        var upperLeft: MKMapPoint = self.heatPoints[0].mapPoint
        var lowerRight = upperLeft
        
        // For arranging all these coordinates into "buckets" at resolution 0
        let bucketCount = MapConstants.ZoomLevelZeroPoints * MapConstants.ZoomLevelZeroPoints
        var buckets = [Double](repeating: 0.0, count:bucketCount)
        
        for heatPoint in self.heatPoints {
            let coord = heatPoint.mapPoint
            // Find the overall upper left and lower right corners,
            // used for building the boundingMapRect MKOverlay property
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
            
            if heatPoint.heatValue > maxValue {
                maxValue = heatPoint.heatValue
            }
            
            // Now put this coord into its respective bucket,
            // to help determine the max value at zoom level 0
            let col = Int(coord.x / Double(MapConstants.ZoomLevelTwentyPoints / MapConstants.ZoomLevelZeroPoints));
            let row = Int(coord.y / Double(MapConstants.ZoomLevelTwentyPoints / MapConstants.ZoomLevelZeroPoints));
            
            let offset = Int(MapConstants.ZoomLevelZeroPoints * row + col);
            
            buckets[offset] += heatPoint.heatValue
        }
        
        for i in 0..<(MapConstants.ZoomLevelZeroPoints * MapConstants.ZoomLevelZeroPoints) {
            if buckets[i] > zoomedOutMaxValue {
                zoomedOutMaxValue = buckets[i];
            }
        }
        
        let rectHeight = lowerRight.y - upperLeft.y + 100000
        let rectWidth = lowerRight.x - upperLeft.x + 100000
        let paddedUpperLeft = MKMapPointMake(upperLeft.x - 50000, upperLeft.y - 50000)
        boundingMapRect = MKMapRect(origin: paddedUpperLeft, size: MKMapSizeMake(rectWidth, rectHeight))
        
        let centerMapPoint = MKMapPointMake(upperLeft.x + (rectWidth/2), upperLeft.y + (rectHeight/2))
        coordinate = MKCoordinateForMapPoint(centerMapPoint)        
    }


    // MARK: Called by Overlay Renderer
    func mapPointsWithHeatIn(rect mapRect:MKMapRect, scale:MKZoomScale) -> [HeatPoint] {
         var heatPointsInRect = [HeatPoint]()
        
         // Each bucket is a square, sized based on our zoom scale.  We pile multiple
         // nearby points (again, nearby is relative) into a single bucket.
         let bucketDimension = ScalingConstants.ScreenPointsPerBucket / scale

         let heatScalingFactor = computeScaleFactor(using: scale)
        
         for heatPoint in heatPoints {
            if MKMapRectContainsPoint(mapRect, heatPoint.mapPoint) {
                let scaledHeatValue = heatPoint.heatValue / heatScalingFactor
                
                let originalX  = heatPoint.mapPoint.x
                let originalY  = heatPoint.mapPoint.y
                // Want to put this point at the center of a scaled square (tile)
                let toBucketCenter = Double(bucketDimension/2)
                let bucketX = originalX.truncatingRemainder(dividingBy: Double(bucketDimension))
                let bucketY = originalY.truncatingRemainder(dividingBy: Double(bucketDimension))
                
                let myBucketX = originalX - bucketX + toBucketCenter
                let myBucketY = originalY - bucketY + toBucketCenter
                
                if let existingPointIndex = heatPointsInRect.index(where: {
                    $0.mapPoint.x == myBucketX && $0.mapPoint.y == myBucketY
                }) {
                    heatPointsInRect[existingPointIndex].heatValue += scaledHeatValue;
                }
                else {
                    let scaledHeatPoint = HeatPoint(mapPoint: MKMapPointMake(myBucketX, myBucketY), heatValue: scaledHeatValue)
                    heatPointsInRect.append(scaledHeatPoint)
                }
                
            }
         }
        return heatPointsInRect
    }
    
    // MARK: helper functions
    private func computeScaleFactor(using scale:MKZoomScale) -> Double {
        let zoomScale = Double(log2(1/scale))
        let slope = (zoomedOutMaxValue - maxValue) / Double(MapConstants.ZoomLevels - 1)

        let x = pow(zoomScale, ScalingConstants.ScalePower) / pow(Double(MapConstants.ZoomLevels), (ScalingConstants.ScalePower - 1))
        var scaleFactor = (x - 1) * slope + maxValue
        
        if (scaleFactor < maxValue) {
            scaleFactor = maxValue
        }
        return scaleFactor
    }
}

struct HeatPoint {
    let mapPoint: MKMapPoint
    var heatValue: Double
}
