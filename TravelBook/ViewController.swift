//
//  ViewController.swift
//  TravelBook
//
//  Created by Nazlı Bekeç on 25.01.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{

    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    var selectedTitle = ""
    var selectedID : UUID?
    var anotationTitle = ""
    var anotationSubtitle = ""
    var anotationLatitude = Double()
    var anotationLongitude = Double()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var saveButtonClicked: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        //Kullanıcının konumunu alma
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()   //uygulamayı kullanırken konumu kullanma
        locationManager.startUpdatingLocation()

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        
        //Kullanıcının ne kadar süreyle bastığını belirleme.
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //Hide Keyboard
        let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer2)
        
        if selectedTitle != "" {
            
            saveButtonClicked.isHidden = true
            
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            //id si istediğim id e eşit olanları çağır
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do {
               let results = try context.fetch(fetchRequest)
                if results.count > 0{
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            anotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                anotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    anotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        anotationLongitude = longitude
                                        
                                        let anotation = MKPointAnnotation()
                                        anotation.title = anotationTitle
                                        anotation.subtitle = anotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: anotationLatitude, longitude: anotationLongitude)
                                        anotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(anotation)
                                        nameText.text = anotationTitle
                                        commentText.text = anotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                        }
                        }
                        }
                        }
                    }
                }
            } catch {
                print("error")
            }
        } else {
            //Add New Data
        }
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }

    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            
            //Dokunulan noktayı al.
            let touchedPoint = gestureRecognizer.location(in: mapView)
            //Dokunulan noktanın koordinatlarını al.
            let touchedCoordinate = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //her dokunduğunda enlem boylam değişkenlerine atanır.
            choosenLatitude = touchedCoordinate.latitude
            choosenLongitude = touchedCoordinate.longitude
            
            //Pin oluştur.
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
        
    }
    //update edilen location ları dizi şeklinde veriyor.
    @objc func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == ""{
            
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //Zoom
            let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
       
    }
    //Pin özelleştirme
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.green
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //Pine tıklandığında ne olacak.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            let requestLocation = CLLocation(latitude: anotationLatitude, longitude: anotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                // closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.anotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        if nameText.text == "" {
            makeAlert(titleInput: "Error!", messageInput: "Name not found!")
        } else if commentText.text == ""{
            makeAlert(titleInput: "Error!", messageInput: "Comment not found!")
        } else if choosenLatitude == 0 && choosenLongitude == 0 {
            makeAlert(titleInput: "Error!", messageInput: "Place not found!")
        } else {
            newPlace.setValue(nameText.text, forKey: "title")
            newPlace.setValue(commentText.text, forKey: "subtitle")
            newPlace.setValue(choosenLatitude, forKey: "latitude")
            newPlace.setValue(choosenLongitude, forKey: "longitude")
            newPlace.setValue(UUID(), forKey: "id")
            do {
                try context.save()
                print("success")
            } catch {
                print("error")
            }
        }
        
        //kaydettikten sonra listeye geri dönme işlemi.
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
        @objc func makeAlert(titleInput: String, messageInput: String) {
            let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(okButton)
            self.present(alert, animated: true)

            
    }
}



