
//
//  DetailFlightController.swift
//  CheckTrip
//
//  Created by Lusenii Kromah on 10/16/16.
//  Copyright © 2016 Derivative. All rights reserved.
//

import UIKit
import Firebase
class DetailFlightController: UIViewController {
    
    @IBOutlet weak var depTextView: UILabel!
    @IBOutlet weak var arvTextView: UILabel!
    @IBOutlet weak var departureTerminalLabel: UILabel!
    @IBOutlet weak var arrivalTerminalLabel: UILabel!
    @IBOutlet weak var departureGateLabel: UILabel!
    @IBOutlet weak var arrivalGateLael: UILabel!
    
    
    
    @IBOutlet weak var departureTimeLabel: UILabel!
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!
    
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    
    var firebaseRef: FIRDatabaseReference!
    
    var flightNumber: String!
    var flightDate: String!
    var airlineCode: String!
    var willCheckBag: Bool!
    
    var flightStatsUrl: String = "https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/"
    var tsaURL: String = "http://apps.tsa.dhs.gov/MyTSAWebService/GetTSOWaitTimes.ashx?ap="
    var flightInfo = FlightInfo()
    var tsaInfo = [TSAInfo]()
    var flightData:[String:String]! = [:]
    var averageTime = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureStorage()
        
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        
        view.addSubview(spinner)
        
        spinner.startAnimating()
        
        
        
        let URL = self.flightStatus(airlineCode, airlineNumber: flightNumber, date: flightDate)
        self.getLatestInfo(URL)
        
        //let URLForTSA: String = "http://apps.tsa.dhs.gov/MyTSAWebService/GetTSOWaitTimes.ashx?ap=ATL&output=json"
        let URLForTSA = self.TSAURL("SEA")
        self.getTSAInfo(URLForTSA)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func TSAURL(_ depShortCode: String) -> String{
        //break up date
        let url = tsaURL.appending("\(depShortCode)&output=json")
        return url
        
    }
    
    func getTSAInfo(_ url: String) {
        let request = URLRequest(url: URL(string: url)! as URL)
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            print(data)
            // Parse JSON data
            if let data = data {
                
                self.tsaInfo = self.parseTSAJsonData(data: data as NSData)
                
            }
            
        })
        
        task.resume()
    }
    
    func parseTSAJsonData(data: NSData) -> [TSAInfo] {
        
        var tsaInfo = [TSAInfo]()
        
        do {
            let jsonResult = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            
            print(jsonResult)
            let jsonTSAs = jsonResult?["WaitTimes"] as! [AnyObject]
            for jsonTSA in jsonTSAs {
                let info = TSAInfo()
                info.CheckpointIndex = jsonTSA["CheckpointIndex"] as! String
                info.Created_Datetime = jsonTSA["Created_Datetime"] as! String
                if(jsonTSA["WaitTime"] as! String == "1"){
                    info.WaitTimeIndex = "0 min"
                    averageTime += 0
                }else if(jsonTSA["WaitTime"] as! String == "2"){
                    info.WaitTimeIndex = "1 - 10 min"
                    averageTime += 5
                }else if(jsonTSA["WaitTime"] as! String == "3"){
                    info.WaitTimeIndex = "11 - 20 min"
                    averageTime += 15
                }else if(jsonTSA["WaitTime"] as! String == "4"){
                    info.WaitTimeIndex = "21 - 30 min"
                    averageTime += 25
                }else if(jsonTSA["WaitTime"] as! String == "5"){
                    info.WaitTimeIndex = "31 - 45 min"
                    averageTime += 38
                }else if(jsonTSA["WaitTime"] as! String == "6"){
                    info.WaitTimeIndex = "46 - 60 min"
                    averageTime += 53
                }else if(jsonTSA["WaitTime"] as! String == "7"){
                    info.WaitTimeIndex = "61 - 90 min"
                    averageTime += 75
                }else if(jsonTSA["WaitTime"] as! String == "8"){
                    info.WaitTimeIndex = "91 - 120 min"
                    averageTime += 105
                }else{info.WaitTimeIndex = "120+ min"
                      averageTime += 120
                }
                
                tsaInfo.append(info)
            }
            averageTime /= 25
            
        } catch {
            print(error)
        }
        
        return tsaInfo
    }
    
    
    func flightStatus(_ airlineName:String,airlineNumber:String,date:String) -> String{
        //break up date
        
        let dataArr:[String] = date.components(separatedBy: "/")
        
        let year = dataArr[0]
        let month = dataArr[1]
        let day = dataArr[2]
        let url = flightStatsUrl.appending("\(airlineName)/\(airlineNumber)/dep/\(year)/\(month)/\(day)?appId=ebdf085d&appKey=1668e8d129b1686e7945852643b0ae44&utc=false")
        
        
        return url
        
    }
    
    func getLatestInfo(_ url: String) {
        let request = URLRequest(url: URL(string: url)! as URL)
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            // Parse JSON data
            if let data = data {
                
                
                self.flightData = self.parseJsonData(data)
                
         
                self.setLabels()
            }
            
        })
        
        task.resume()
    }
    func setLabels(){
        
        OperationQueue.main.addOperation {
            
            guard let departureLabel = self.flightData["departureAirportFsCode"] else {
                self.depTextView.text = "N/A"
                return  }
            self.depTextView.text = departureLabel
            
            
            
            self.departureTerminalLabel.text = "Terminal \(self.flightData["departureTerminal"]!)"
            self.departureGateLabel.text = "Gate \(self.flightData["departureGate"]!)"
            
            self.arvTextView.text = self.flightData["arrivalAirportFsCode"]!
            self.arrivalTerminalLabel.text = "Terminal \(self.flightData["arrivalTerminal"]!)"
            
            self.arrivalGateLael.text = "Gate \(self.flightData["arrivalGate"]! )"
            
            self.spinner.stopAnimating()
            
//            self.departureTimeLabel.text = self.flightInfo.schdepartureTimeNumberLabel
//            
//            
//            
//            self.arrivalTimeLabel.text = self.flightInfo.scharrivalFlightTimeLabel
            
        }
    }
    
    func parseJsonData(_ data: Data) -> [String:String] {
        
        var flightDictionary = [String:String]()
        
        do {
            let jsonResult = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            
            let jsonFlights = jsonResult?["flightStatuses"] as! [AnyObject]
            
            for jsonFlight in jsonFlights {
                flightDictionary["departureAirportFsCode"] =  jsonFlight["departureAirportFsCode"] as? String
                flightDictionary["arrivalAirportFsCode"] =  jsonFlight["arrivalAirportFsCode"] as? String
                
                let gateInfo = jsonFlight["airportResources"] as! [String:AnyObject]
//                flight.arrivalTerminal = gateInfo["arrivalTerminal"] as! String
                flightDictionary["arrivalTerminal"] =  gateInfo["arrivalTerminal"] as? String
//                flight.arrivalGate = gateInfo["arrivalGate"] as! String
                flightDictionary["arrivalGate"] =  gateInfo["arrivalGate"] as? String
//                flight.departureTerminal = gateInfo["departureTerminal"] as! String
                flightDictionary["departureTerminal"] =  gateInfo["departureTerminal"] as? String
//                flight.departureGate = gateInfo["departureGate"] as! String
                flightDictionary["departureGate"] =  gateInfo["departureGate"] as? String
                
                
                
                let schDep = jsonFlight["departureDate"] as! [String:AnyObject]
//                flight.schdepartureTimeNumberLabel = schDep["dateLocal"] as! String
                flightDictionary["dateLocal"] =  schDep["dateLocal"] as? String
                let schArr = jsonFlight["arrivalDate"] as! [String:AnyObject]
//                flight.scharrivalFlightTimeLabel = schArr["dateLocal"] as! String
                flightDictionary["dateLocal"] =  schArr["dateLocal"] as? String
                
                if !willCheckBag {
                    flightDictionary["willCheckBag"] = "false"
                }
                    flightDictionary["willCheckBag"] = "true"
                
//                flightDictionary["departureAirportAddress"]  = airports[0]["street1"] as? String
            
                
            }
            
            let appendix = jsonResult?["appendix"] as! [String:AnyObject]
            
            let airports = appendix["airports"] as! [AnyObject]
            
            let departureAirport = airports[0]
            
            
            flightDictionary["departureAirportAddress"] = departureAirport["street1"] as? String
            
            print()
            
                print()
        
            
            
        } catch {
            print(error)
        }
        return flightDictionary
    }
    
    
    
    
    func configureStorage() {
     firebaseRef = FIRDatabase.database().reference()
    }
    
    @IBAction func saveFlight(_ sender: UIBarButtonItem) {
        
        let user = FIRAuth.auth()?.currentUser
        guard let uid = user?.uid else {
        
            return
        }
        
        let reference = firebaseRef.database.reference().child("users").child(uid).child("flights").childByAutoId()
            
            flightData["flightId"] = reference.key
                
            reference.setValue(flightData){ (error, ref) -> Void in
                if error != nil {
                    print("\(error)")
                }
            }
        
        
        dismiss(animated: true, completion: nil)
        
        
        
    }
}
