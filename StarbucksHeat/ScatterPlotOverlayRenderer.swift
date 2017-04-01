//
//  ScatterPlotOverlayRenderer.swift
//  StarbucksHeat
//
//  Created by Joy Kendall on 3/31/17.
//  Copyright © 2017 Joy. All rights reserved.
//

import Foundation
import MapKit

class ScatterPlotOverlayRenderer: MKOverlayRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let scatterOverlay = self.overlay as! ScatterPlot
        let scatterPointsInThisRect = scatterOverlay.scatterPointstIn(rect: mapRect, scale: zoomScale)
  
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)

        // for each of our scatter points in this rectangle, decide how big it should based on the zoomScale
        var countPoints = 0
        for mapPoint in scatterPointsInThisRect {
            let userSpacePoint = self.point(for: mapPoint)
            
           // let plotRect = CGRect(origin: userSpacePoint, size: CGSize(width: 10 * (1/zoomScale), height: 10 * (1/zoomScale)))
           // context.fill(plotRect)
            
            let plotCircle = UIBezierPath(arcCenter: userSpacePoint, radius: 5 * (1/zoomScale), startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            context.addPath(plotCircle.cgPath)
            context.fillPath()
            countPoints += 1
        }
        
        print("There were \(countPoints) in this tile")
 
       // colorMapTiles(mapRect, in: context)
    }
    
    // Super useful debugging method that helps visualize how the renderer works - it breaks
    // the screen up into tiles, which halve in dimensions with each "zooming in", where it
    // stops at 256 (zoom level 20).  So the draw method gets called many times per scale, each
    // for a different screen tile.
    private func colorMapTiles(_ mapRect: MKMapRect, in context: CGContext) {
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        
        let userRect = self.rect(for: mapRect)
        context.fill(userRect)
        print("origin: \(userRect.origin)")
    }
}
