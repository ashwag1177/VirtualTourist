//
//  ViewController.swift
//  VirtualTourist
//
//  Created by  ashwaq marzouq on 26/10/1444 AH.
//

import UIKit
import MapKit
import CoreData
import Kingfisher


class TravelLocationsMapViewController: UIViewController {
   
    @IBOutlet weak var mapView: MKMapView!
    var annotations = [MKAnnotation]()
    var pin: Pin!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapOnMap(_:)))
        mapView.addGestureRecognizer(longGesture)
        fetch()
        showPins()
    }
    
    
    func fetch(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationData", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        do {
            try fetchedResultsController.performFetch()
        }catch {
            fatalError("The fetch could not be performed : \(error.localizedDescription)")
        }
    }
    
    @objc func tapOnMap(_ sender: UIGestureRecognizer){
         if sender.state == .began {
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            let pin = Pin(context: DataController.shared.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            let annotation = PinAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            annotation.pinObjc = pin
            do {
                try DataController.shared.viewContext.save()
            }
            catch {
                print(error)
            }
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(self.annotations)
        }
    }
    
    func showPins() {
        for location in fetchedResultsController.fetchedObjects! {
            let latitude = location.latitude
            let longitude = location.longitude
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = PinAnnotation()
            annotation.coordinate = coordinate
            self.annotations.append(annotation)
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(self.annotations)
        }
    }
    
}

extension TravelLocationsMapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
         
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoAlbumViewController
        
        fetch()
        if let result = fetchedResultsController.fetchedObjects {
            for pin in result {
                if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                    controller.pin = pin
                    navigationController!.pushViewController(controller, animated: true)
                    mapView.deselectAnnotation(view.annotation, animated: true)
                    present( controller, animated: true, completion: nil)
                }
            }
        }
    }
}
