//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by  ashwaq marzouq on 30/10/1444 AH.
//

import UIKit
import MapKit
import CoreData
import Kingfisher

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var centralIndicator: UIActivityIndicatorView!
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var pin: Pin!
    var photoArray = [URL]()
    var insert: [IndexPath]!
    var delete: [IndexPath]!
    var update: [IndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        noImage.isHidden = true
        centralIndicator.isHidden = false
        showLocationOnMap()
        setFlowLayout()
        fetch()
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            getImagesFromFlikr()
        }
    }
    
    
    private func showLocationOnMap() {
        guard let pin = pin else { return }
        let latitude = CLLocationDegrees(pin.latitude)
        let longitude = CLLocationDegrees(pin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = PinAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        print(annotation.coordinate)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    func fetch() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationData", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func getImagesFromFlikr(){
        self.noImage.isHidden = false
        self.noImage.text = "fetching photos..."
        self.centralIndicator.startAnimating()

        FlickrClient.sharedInstance().getImageFormFlicker(latitude: pin.latitude, longitude: pin.longitude, { (success, data, error)  in
            guard error == nil else {
                print(error!)
                let alert = UIAlertController(title: "Alert", message: "You are not conected to the internet", preferredStyle: .alert )
                alert.addAction(UIAlertAction (title: "OK", style: .default, handler: { _ in
                    return
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }
            if success {
                if let photo = data as? [PhotoParse] {
                    for i in photo {
                        self.photoArray.append(URL(string: i.url_m)!)
                    }
                    self.getImages()
                } else {
                    DispatchQueue.main.async {
                        self.centralIndicator.stopAnimating()
                        self.noImage.isHidden = false
                        self.noImage.text = "No Images!"
                        print("no images for this Location")
                    }
                }
            }
            DispatchQueue.main.async {
              self.noImage.isHidden = true
              self.centralIndicator.stopAnimating()
              self.centralIndicator.isHidden = true
            }
        })
    }
    
    func getImages(){
        for url in photoArray {
            self.addPhotosToCoreData(url:url.absoluteString)
        }
    }
    
    func addPhotosToCoreData(url:String) {
        let photo = Photo(context: DataController.shared.viewContext)
        photo.pin = pin
        photo.imageURL = url
        photo.creationData = Date()
        do {
            try DataController.shared.viewContext.save()
        }catch {
            print(error)
        }
    }
    
    func setFlowLayout(){
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    @IBAction func newCollection(_ sender: Any) {
        for photos in fetchedResultsController.fetchedObjects! {
            DataController.shared.viewContext.delete(photos)
        }
        try? DataController.shared.viewContext.save()
        getImagesFromFlikr()

    }
    
    func downloadImage(url:URL, completion: @escaping (_ data: Data?,_ error: Error?) -> Void){
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if error == nil {
                if let data = data {
                    completion(data,nil)
                }
                
            }else {
                completion(nil,error)
            }
        }
        dataTask.resume()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! CollectionViewCell
        cell.image.kf.indicatorType = .activity
        let photos = fetchedResultsController.fetchedObjects! as [Photo]
        _ = photos[indexPath.row]
        let url = URL(string: photos[indexPath.row].imageURL!)!
        cell.image.kf.setImage(with: url)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let deleteImage = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(deleteImage)
        do {
            try DataController.shared.viewContext.save()
        }catch {
            print(error)
        }
        
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insert = [IndexPath]()
        delete = [IndexPath]()
        update = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            insert.append(newIndexPath!)
            break
        case .delete:
            delete.append(indexPath!)
            break
        case .update:
            update.append(indexPath!)
            break
        case .move:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insert {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.delete {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.update {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }

}


extension PhotoAlbumViewController : MKMapViewDelegate {
    
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
    
}

