//
//  HeatMapOverlayRenderer.swift
//  StarbucksHeat
//
//  Created by Joy Kendall on 3/29/17.
//  Copyright © 2017 Joy. All rights reserved.
//

import Foundation
import MapKit

class HeatMapOverlayRenderer: MKOverlayRenderer {
    
    
    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
        scaleMe()
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let HeatRadiusInPoints = 48
        let heatMapOverlay = self.overlay as! HeatMap
        let mapPointsWithHeat = heatMapOverlay.mapPointsWithHeatIn(rect: mapRect, scale: zoomScale)
        
        let screenRect = self.rect(for: mapRect)

        let screenColumns = Int(screenRect.size.width * zoomScale)
        let screenRows = Int(screenRect.size.height * zoomScale)
        var heatValuesWithinRect = [Double](repeating: 0.0, count:screenColumns * screenRows)
        
        for heatPoint in mapPointsWithHeat {
            if heatPoint.heatValue > 0 {
                // Figure out where we are on the screen right now
                let screenPoint = self.point(for: heatPoint.mapPoint)
    
                let matrixCoord = CGPoint(x: (screenPoint.x - screenRect.origin.x) * zoomScale, y:
                                                  (screenPoint.y - screenRect.origin.y) * zoomScale)
                
                for i in 0..<(2 * HeatRadiusInPoints) {
                    for j in 0..<(2 * HeatRadiusInPoints) {
                        //find the array index
                        let column = Int(matrixCoord.x - CGFloat(HeatRadiusInPoints + i))
                        let row = Int(matrixCoord.y - CGFloat(HeatRadiusInPoints + j))
                        
                        // Check the bounds of the row and column
                        if row >= 0 && column >= 0 && row < screenRows && column < screenColumns {
                            let index = screenColumns * row + column
                            heatValuesWithinRect[index] += heatPoint.heatValue //* _scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i];
                        }
                
                    }
                }
            }
        }
  
        // Now, go through the array we just built and colorize based on value and zoom scale
        for index in 0..<heatValuesWithinRect.count {
            // Don't bother if the value here isn't greater than zero
            if heatValuesWithinRect[index] > 0 {
                let heatValue = heatValuesWithinRect[index]
                
                let (red, green, blue) = colorize(value: CGFloat(heatValue), between: 0.0, and: 1.0)
                let alpha = min(0.8, CGFloat(heatValue))
                context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
                let column = index % screenColumns
                let row = index / screenColumns
                
                // Re-scale to match current zoomScale and visible rectangle
                let thisPointsScreenRect = CGRect(x: screenRect.origin.x + CGFloat(column) / zoomScale, y: screenRect.origin.y + CGFloat(row) / zoomScale, width: 1/zoomScale, height: 1/zoomScale)

                context.fill(thisPointsScreenRect)
            }
        }
    }

    private func scaleMe() {
        
    }
    
    // Note: Methods of colorizing are many, and I liked this one best - it's one that MATLAB has used for some time,
    // from what I gathered.
    private func colorize(value: CGFloat, between minimum: CGFloat, and maximum: CGFloat) -> (CGFloat, CGFloat, CGFloat)
    {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        
        if value <= 0 {
            (red, green,blue) = (0.0, 0.0, 0.0)
        } else if value < 0.125 {
            (red, green,blue) = (0.0, 0.0, 4 * (value + 0.125))
        } else if value < 0.375 {
            (red, green,blue) = (0.0, 4 * (value - 0.125), 1.0)
        } else if value < 0.625 {
            (red, green,blue) = (4 * (value - 0.375), 1.0, 1 - 4 * (value - 0.375))
        } else if value < 0.875 {
            (red, green,blue) = (1.0, 1 - 4 * (value - 0.625), 0.0)
        } else {
            (red, green,blue) = (max(1 - 4 * (value - 0.875), 0.5), 0.0, 0.0)

        }
        return (red, green, blue)
    }
}
