//
//  VistaMapa.swift
//  TrackerGPS
//
//  Created by iñaki on 23/1/18.
//  Copyright © 2018 iñaki. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CoreLocation

class VistaMapa: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {    
    
    var recorrido: Recorrido = Recorrido()
    var subirDatos: Bool = false
    //variable para la distancia del recorrido
    var distanciaTotal: Double = 0
    
    @IBOutlet var mapView: MKMapView!
    @IBAction func botonVolver(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addAnotations()
        mapView.region.center = CLLocationCoordinate2D(latitude: recorrido.localizaciones[0].latitude, longitude: recorrido.localizaciones[0].longitude)
        mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        
        if(subirDatos) {
            subirAFirebase()
        }
    }
    
    //subir a firebase
    func subirAFirebase() {
        
        //recorrido a subir
        var ref: DocumentReference? = nil
        ref = db.collection("recorridos").addDocument(data: [
            "fechaInicio": recorrido.fechaInicio,
            "fechaFin": recorrido.fechaFin,
            "tiempoT": recorrido.tiempoT,
            "id": recorrido.id,
            "tipo": recorrido.tipo,
            "localizaciones": recorrido.localizaciones
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addAnotations(){
        mapView?.delegate = self
        //transformacion de [GeoPoint] a CLLocation
        var cambio: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        
        //variables calcular distancia
        var loc1: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var loc2: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var vControl = 0
        
        for location in recorrido.localizaciones {
            let lc: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            cambio.append(lc)
            
            //controlar el punto anterior con el nuevo
            if (vControl == 2){
                loc1 = loc2
                loc2 = lc
            }
            //los 2 primeros puntos que coge
            if(vControl == 0){
                loc1 = lc
                vControl = 1
            }else if (vControl == 1){
                loc2 = lc
                vControl = 2
            }
            
            if (vControl == 2){
                self.distanciaTotal += calcularMetrosEntreDosPuntos(localizacion1: loc1,localizacion2: loc2)
            }
            //numero += 1
        }
        // a dibujar
        let polyline = MKPolyline(coordinates: cambio, count: cambio.count)
        mapView?.add(polyline)
        mapView?.delegate = self        
        
        mapView(mapView, rendererFor: polyline)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //Return an `MKPolylineRenderer` for the `MKPolyline` in the `MKMapViewDelegate`s method
        if let polyline = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyline)
            testlineRenderer.strokeColor = .blue
            testlineRenderer.lineWidth = 2.0
            return testlineRenderer
        }
        fatalError("Something wrong...")
        //return MKOverlayRenderer()
    }
    
    
    func calcularMetrosEntreDosPuntos(localizacion1: CLLocationCoordinate2D, localizacion2: CLLocationCoordinate2D) -> Double{
        let radioTierra = 3959.0 //en millas
        let calc1 = localizacion2.latitude - localizacion1.latitude
        let calc2 = localizacion2.longitude - localizacion1.longitude
        
        //de grados a radianes
        let grado1 = calc1 * .pi / 180
        let grado2 = calc2 * .pi / 180
        
        let a = sin(grado1/2) * sin(grado1/2) + cos(localizacion1.latitude * .pi / 180) * cos(localizacion2.latitude * .pi / 180) * sin(grado2/2) * sin(grado2/2)
        let c = 2 * atan2(sqrt(a),sqrt(1-a))
        let d = radioTierra * c
        
        return round((d / 0.62137) * 1000)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "aDetalles"){
            let destino = segue.destination as! VistaDetalles
            
            //pasar al destino el recorrido
            destino.recorrido = self.recorrido
            destino.distanciaTotal = self.distanciaTotal
            
        }else{}
    }
    

    
    
}

