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
    
    private enum MapRendererType {
        case ScatterPlot
        case HeatMap
    }
    private var currentMapType = MapRendererType.ScatterPlot
    private var heatMap: HeatMap?
    private var scatterMap: ScatterPlot?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let heatPoints = parseData() {
            heatMap = HeatMap(with: heatPoints)
            scatterMap = ScatterPlot(with: heatPoints)

            updateMapOverlay()
            
            // Position and zoom the map to just fit the heatmap data on screen
            mapView.setVisibleMapRect(scatterMap!.boundingMapRect, animated: true)
        }
    }

    @IBAction private func changeMapOverlayType(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            currentMapType = MapRendererType.ScatterPlot
        case 1:
            currentMapType = MapRendererType.HeatMap
        default:
            break
        }
        updateMapOverlay()
    }
    
    private func updateMapOverlay() {
        if currentMapType == MapRendererType.ScatterPlot {
            mapView.remove(heatMap!)
            mapView.add(scatterMap!)
            
        } else {
            mapView.remove(scatterMap!)
            mapView.add(heatMap!)
        }
       
    }
    
    // MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let heatOverlay = overlay as? HeatMap {
           return HeatMapOverlayRenderer(overlay: heatOverlay)
        }
        else {
            return ScatterPlotOverlayRenderer(overlay: overlay)
        }
    }
    
    private func showAnnotations(heatPoints: [HeatPoint]) {
        // This would be unkind for this many points!!

        for heatPoint in heatPoints {
            let annotation = MKPointAnnotation()
            let mapPoint = heatPoint.mapPoint
            let coord = MKCoordinateForMapPoint(mapPoint)
            annotation.coordinate = coord
            mapView.addAnnotation(annotation)
        }

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

