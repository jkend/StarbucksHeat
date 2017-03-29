//
//  ViewController.swift
//  StarbucksHeat
//
//  Created by Joy Kendall on 3/27/17.
//  Copyright © 2017 Joy. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet private weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let heatPoints = parseData() {
            let heatMap = HeatMap(with: heatPoints)
        
            // Position and zoom the map to just fit the heatmap data on screen
            mapView.setVisibleMapRect(heatMap.boundingMapRect, animated: true)
            print("rectangle: \(heatMap.boundingMapRect)")
            // Add the heatmap overlay to the map view
            mapView.add(heatMap)
 
            print("number found: \(heatPoints.count)")
            // This would be unkind for this many points!!
            /*
            for heatPoint in heatPoints {
                let annotation = MKPointAnnotation()
                let mapPoint = heatPoint.mapPoint
                let coord = MKCoordinateForMapPoint(mapPoint)
                annotation.coordinate = coord
                mapView.addAnnotation(annotation)

            }
             */
        }
    }

    // MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let heatMapRenderer = HeatMapOverlayRenderer(overlay: overlay)
        return heatMapRenderer
    }
    
    // Parsing really belongs elsewhere, but it's okay here for now.
    private func parseData() -> [HeatPoint]? {
        let dataURL = Bundle.main.url(forResource:"xy4y-c4mk-US", withExtension: "json")
        guard let fileData = NSData(contentsOf: dataURL!) else {
            return nil
        }
        let allStores = try? JSONSerialization.jsonObject(with: fileData as Data, options: [])

        // We only care about the location of each store - that's what
        // the heap map will use.

        var pointsArray =  [HeatPoint]()
        for store in allStores as! [Dictionary<String, Any>] {
            let coordinatesJSON = store["coordinates"] as! [String: Any]
            let latitude = coordinatesJSON["latitude"]
            let longitude = coordinatesJSON["longitude"]
            if let lat = Double(latitude as! String), let lng = Double(longitude as! String) {

                let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let hp = HeatPoint(mapPoint: MKMapPointForCoordinate(location), heatValue: 1)

                pointsArray.append(hp)
            }
        }
        return pointsArray
    }
}

