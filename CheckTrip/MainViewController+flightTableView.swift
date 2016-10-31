//
//  MainViewController+flightTableView.swift
//  CheckTrip
//
//  Created by Lusenii Kromah on 10/23/16.
//  Copyright © 2016 Derivative. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit


//TableView extension of MainViewController
extension MainViewController: UITableViewDataSource,UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        
        if flights.count == 0 {
            flightTableView.backgroundView = emptyFlightView
            flightTableView.separatorColor = .white
            return flights.count
        }
        
        flightTableView.backgroundView = nil
        return flights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",for:indexPath) as? FlightViewCell
        
        let flight = flights[indexPath.row]
        
        //departure gate
        cell?.departureFlightLabel?.text = "ATL"
        
        cell?.departureTimeNumberLabel?.text = "12:00 pm"
        
        cell?.departureFlightDateLabel?.text = "12/12/2016"
        
        cell?.departureGateLabel?.text = "Gate: 1"
        
        cell?.departureTerminalLabel?.text = "Terminal: A"
        
        //arrival gate
        cell?.arrivalFlightLabel?.text = "SEA"
        

        
        
        cell?.arivalFlightTimeLabel?.text = "3:00 AM"
        
        cell?.arivalFlightDateLabel?.text = "01/01/2016"
        
        cell?.arrivalGateLabel?.text = "Gate:2"
        
        cell?.arrivalTerminalLabel?.text = "Terminal: B"
        
        return cell!
    }
    
//    func stringToDate(date:String) -> String{
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM/dd/yyy"
//        
//        return formatter.date(from: date)?.description
//    }
//    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let flight = flights[indexPath.row]
        guard let airportAddreess = flight.departureAirportAddress else {
            return
        }
        
        CLGeocoder().geocodeAddressString(airportAddreess) { (placemark:[CLPlacemark]?, error:Error?) in
            if error != nil{
                return
            }
            
            
            guard let place = placemark else {
            
                return
            }
            let airportLat = Double((place[0].location?.coordinate.latitude)!)
            let airportLng = Double((place[0].location?.coordinate.longitude)!)
            
            print(GoogleDestinationService.computeDuration(self.latitude, originLongitude: self.longitude, destinationLatitude: airportLat, destinationLongitude: airportLng))
            
            let url = "http://apps.tsa.dhs.gov/MyTSAWebService/GetTSOWaitTimes.ashx?ap=\(flight.departureAirportFsCode!)"
            
            let tsaParser = TSAParser()
            tsaParser.parseFeed(feedUrl: url, completionHandler: { (waitTimes:[(checkpointIndex: String, waitTime: String)]) in
                self.waitTimesRSS = waitTimes
                
                print(waitTimes)
            })

        }
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Delete the row from the data source
            flights.remove(at: indexPath.row)
            
        }
        
        flightTableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    @IBAction func close(segue:UIStoryboardSegue){
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // Social Sharing Button
        let shareAction = UITableViewRowAction(style:
            UITableViewRowActionStyle.default, title: "Share", handler: { (action,
                indexPath) -> Void in
                
                let flight = self.flights[indexPath.row]
                
                let defaultText = "My Flight arrives at \(flight.arrivalAirportFsCode!) at 4:00 pm.\n  BAGS: Checked in"
                
                
                
                self.sendSMS(attachment: defaultText)
//                
//                let activityController = UIActivityViewController(activityItems:
//                    [defaultText], applicationActivities: nil)
//                self.present(activityController, animated: true, completion: nil)
        })
        
        shareAction.backgroundColor = UIColor.checkTripBlue()
        
        // Delete button
        let deleteAction = UITableViewRowAction(style:
            UITableViewRowActionStyle.default, title: "Delete",handler: { (action,
                indexPath) -> Void in
                // Delete the row from the data source
                let flight = self.flights[indexPath.row]
                
                self.deleteFromFirebase(flight:flight)
                
                
                self.flights.remove(at: indexPath.row)
                
                self.flightTableView.deleteRows(at: [indexPath], with: .fade)
                
        })
        
        return [deleteAction, shareAction]
    }
    
    func deleteFromFirebase(flight:Flight){
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            
            return
        }
        
        let user = ref.database.reference().child("users").child(uid)
        
        if let flightId = flight.value(forKey: "flightId") as? String {
            
            _ = user.child("flights").child(flightId).removeValue { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
            }
        }
    }
}
