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
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        
    }
}
