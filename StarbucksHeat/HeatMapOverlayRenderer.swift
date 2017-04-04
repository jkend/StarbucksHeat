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
    
    lazy var scales: [Double] = self.setupScales()
    
    let HeatRadiusInPoints = 48
    let MapTileDimension = 256
    
    // MARK: Draw
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext)
    {
        // Get our mapRect as a CGRect
        let screenRect: CGRect = self.rect(for: mapRect)

        // Because of the tiling the renderer does, values will be cut off unless we use a larger
        // rectangle.  So ask for the heatvalues of a padded, "expanded" rectangle.
        let paddingAmount: CGFloat = 128 / zoomScale
        let expandedRect = CGRect(x: screenRect.origin.x - paddingAmount,
                                  y: screenRect.origin.y - paddingAmount,
                                  width: screenRect.size.width + (2 * paddingAmount),
                                  height: screenRect.size.height + (2 * paddingAmount))

        let expandedMapRect: MKMapRect = self.mapRect(for: expandedRect)
        
        // Ask the overlay for all the heat points in this padded rectangle
        let heatMapOverlay = self.overlay as! HeatMap
        let mapPointsWithHeat = heatMapOverlay.mapPointsWithHeatIn(rect: expandedMapRect, scale: zoomScale)

        // This array will store the heat values based on scale within this fixed-sized tile
        var heatValuesWithinRect = [Double](repeating: 0.0, count:MapTileDimension * MapTileDimension)
        
        for heatPoint in mapPointsWithHeat {
            if heatPoint.heatValue > 0 {
                // Figure out where we are on the screen right now
                let screenPoint = self.point(for: heatPoint.mapPoint)
    
                let gridCoord = CGPoint(x: (screenPoint.x - screenRect.origin.x) * zoomScale,
                                        y: (screenPoint.y - screenRect.origin.y) * zoomScale)
  
                for c in 0..<(2 * HeatRadiusInPoints) {
                    for r in 0..<(2 * HeatRadiusInPoints) {
                        // Check all the points surrounding this tile coordinate, and scale their
                        // heat according to how close they are to this heat point.
                        // Oh yeah, and when doing Swift's absurd type conversions, watch out
                        // where you put your parentheses! Grrr.
                        let column = Int((gridCoord.x - CGFloat(HeatRadiusInPoints) + CGFloat(c)).rounded(.down))
                        let row =  Int((gridCoord.y - CGFloat(HeatRadiusInPoints) + CGFloat(r)).rounded(.down))

                        // Check the bounds of the row and column
                        if row >= 0 && row < MapTileDimension && column >= 0 && column < MapTileDimension {
                            let index = MapTileDimension * row + column
                            heatValuesWithinRect[index] += heatPoint.heatValue * scales[r * 2 * HeatRadiusInPoints + c];
                        }
                    }
                }
            }
        }
  
        // Now, go through the array we just built and colorize based on value and zoom scale
        for index in 0..<heatValuesWithinRect.count {
            // Don't bother if the value here isn't greater than zero
            if heatValuesWithinRect[index] > 0 {
                // Colorize this heat value.
                let (red, green, blue) = colorize(value: CGFloat(heatValuesWithinRect[index]),
                                                  between: 0.0,
                                                  and: 1.0)
                context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
                
                // Now figure out where this color belongs on screen
                let tileColumn = index % MapTileDimension
                let tileRow = index / MapTileDimension
                
                // Re-scale to match current zoomScale and visible rectangle
                let thisPointsScreenRect = CGRect(x: screenRect.origin.x + CGFloat(tileColumn) / zoomScale,
                                                  y: screenRect.origin.y + CGFloat(tileRow) / zoomScale,
                                                  width: 1/zoomScale,
                                                  height: 1/zoomScale)

                context.fill(thisPointsScreenRect)
            }
        }
    }

    // MARK: Scaling values
    // I got this scaling matrix from Ryan Olson's HeatMap project, it really helped!
    private func setupScales() -> [Double] {
        var matrix = [Double](repeating: 0.0, count:2 * HeatRadiusInPoints * 2 * HeatRadiusInPoints)
        
        for c in 0..<2 * HeatRadiusInPoints {
            for r in 0..<2 * HeatRadiusInPoints {
                let distanceSquared = (c - HeatRadiusInPoints) * (c - HeatRadiusInPoints) + (r - HeatRadiusInPoints) * (r - HeatRadiusInPoints)
                let distance = sqrt(Double(distanceSquared))
                
                var scalingFactor = 1 - (distance / Double(HeatRadiusInPoints))
                if scalingFactor < 0 {
                    scalingFactor = 0
                } else {
                    scalingFactor = pow(2, (-distance/10.0)) - pow(2, Double(-HeatRadiusInPoints)/10)
                }
                matrix[r * 2 * HeatRadiusInPoints + c] = scalingFactor
                
            }
        }
        return matrix
    }
    
    // MARK: Colorizing
    // This is the colorizer from Apple's example project HazardMap - the MatLab one was too dark, after all
    private func colorize(value: CGFloat, between minimum: CGFloat, and maximum: CGFloat) -> (CGFloat, CGFloat, CGFloat)
    {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        
        let adjustedValue = sqrt(value)
        
        if adjustedValue > 0.77 {
            (red, green,blue) =  (0.588, 0.294, 0.78)
        }
        else if (adjustedValue > 0.59) {
            (red, green,blue) = (0.784, 0.471, 0.82)
        }
        else if (adjustedValue > 0.46) {
            (red, green,blue) = (1, 0, 0)
        }
        else if (adjustedValue > 0.35) {
            (red, green,blue) = (1, 0.392, 0)
        }
        else if (adjustedValue > 0.27) {
            (red, green,blue) = (1, 0.392, 0)
        }
        else if (adjustedValue > 0.21) {
            (red, green,blue) = (1, 0.784, 0)
        }
        else if (adjustedValue > 0.16) {
            (red, green,blue) = (1, 1, 0.5)
        }
        else if (adjustedValue > 0.12) {
            (red, green,blue) = (0.745, 0.941, 0.467)
        }
        else if (adjustedValue > 0.10) {
            (red, green,blue) = (0.122, 1, 0.31)
        }
        else if (adjustedValue > 0.08) {
            (red, green,blue) = (0.588, 1, 0.941)
        }
        else if (adjustedValue > 0.06) {
            (red, green,blue) = (0.784, 1, 1)
        }
        else if (adjustedValue > 0.04) {
            (red, green,blue) = (0.843, 1, 1)
        }
        else if (adjustedValue > 0.03) {
            (red, green,blue) = (0.902, 1, 1)
        }
        else {
            (red, green,blue) = (0.784, 0.784, 0.784)
        }
        
        return (red, green, blue)
    }
    
    // Note: Methods of colorizing are many, this is apparently one that MATLAB has used for some time.
    // I liked it at first, but eventually decided it was too dark for the low values.
    private func colorizeOld(value: CGFloat, between minimum: CGFloat, and maximum: CGFloat) -> (CGFloat, CGFloat, CGFloat)
    {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        
        let adjustedValue = sqrt(value)
        
        if adjustedValue <= 0 {
            (red, green,blue) = (0.0, 0.0, 0.0)
        } else if adjustedValue < 0.125 {
            (red, green,blue) = (0.0, 0.0, 4 * (adjustedValue + 0.125))
        } else if adjustedValue < 0.375 {
            (red, green,blue) = (0.0, 4 * (adjustedValue - 0.125), 1.0)
        } else if adjustedValue < 0.625 {
            (red, green,blue) = (4 * (adjustedValue - 0.375), 1.0, 1 - 4 * (adjustedValue - 0.375))
        } else if adjustedValue < 0.875 {
            (red, green,blue) = (1.0, 1 - 4 * (adjustedValue - 0.625), 0.0)
        } else {
            (red, green,blue) = (max(1 - 4 * (adjustedValue - 0.875), 0.5), 0.0, 0.0)

        }
        return (red, green, blue)
    }
    
}
