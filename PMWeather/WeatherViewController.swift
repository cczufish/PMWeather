//
//  WeatherViewController.swift
//  PMWeather
//
//  Created by yu on 14-6-20.
//  Copyright (c) 2014年 鱼舒辉. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager:CLLocationManager = CLLocationManager()
    var background = UIImage(named: "background.png")
    
     var loadingIndicator : UIActivityIndicatorView?
     var icon : UIImageView?
     var temperature : UILabel?
     var loading : UILabel?
     var location : UILabel?
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        self.navigationController.navigationBar.hidden = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        getView()
        
        self.view.backgroundColor = UIColor(patternImage: background)
        
        let singleFingerTap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        self.view.addGestureRecognizer(singleFingerTap)
        
        if ( ios8() ) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingLocation()
    }
    
    func getView()
    {
        
        icon = UIImageView(frame: CGRectMake(85,98,150,150))
        self.view.addSubview(icon)
        
        
        // Label
        self.temperature = UILabel(frame: CGRectMake(85,262,150,61))
        self.temperature!.backgroundColor = UIColor.clearColor()
        self.temperature!.textAlignment = NSTextAlignment.Center
        self.temperature!.font = UIFont.systemFontOfSize(36)
        self.temperature!.text = "Hello, Swift"
        self.view.addSubview(self.temperature)
        
        
        self.location = UILabel(frame: CGRectMake(20,46,280,44))
        self.location!.backgroundColor = UIColor.clearColor()
        self.location!.textAlignment = NSTextAlignment.Center
        self.location!.font = UIFont.systemFontOfSize(36)
        self.location!.text = "Hello, Swift"
        self.view.addSubview(self.location)
        
        self.loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.Gray)
        self.loadingIndicator!.frame = CGRectMake(150, 163, 40.0, 40.0)
        self.loadingIndicator!.startAnimating()
        self.view.addSubview(self.loadingIndicator)
        
        
        self.loading = UILabel(frame: CGRectMake(20,271,280,44))
        self.loading!.backgroundColor = UIColor.clearColor()
        self.loading!.textAlignment = NSTextAlignment.Center
        self.loading!.font = UIFont.systemFontOfSize(36)
        self.loading!.text = "Hello, Swift"
        self.view.addSubview(self.loading)
        
        
        var button = UIButton.buttonWithType(UIButtonType.System) as? UIButton
        button!.frame = CGRectMake(200,400,100.0,50.0)
        button!.backgroundColor = UIColor.grayColor()
        button?.setTitleColor(UIColor.redColor(),forState:UIControlState.Normal)
        button?.setTitleColor(UIColor.whiteColor(),forState:UIControlState.Highlighted)
        button?.setTitle("PM2.5",forState:UIControlState.Normal)
        button?.setTitle("PM2.5",forState:UIControlState.Highlighted)
        
        button?.addTarget(self,action:"buttonPressed:",forControlEvents:UIControlEvents.TouchUpInside)
        button!.tag = 100
        self.view.addSubview(button)
        
        
    }
    
    func buttonPressed(sender:UIButton)
    {
        println("test")
        
        var pmListViewController = PMListVC()
        self.navigationController.pushViewController(pmListViewController, animated: true)

    }
    
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let manager = AFHTTPRequestOperationManager()
        let url = "http://api.openweathermap.org/data/2.5/weather"
        println(url)
        
        let params = ["lat":latitude, "lon":longitude, "cnt":0]
        println(params)
        
        manager.GET(url,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!,
                responseObject: AnyObject!) in
                println("JSON: " + responseObject.description!)
                
                self.updateUISuccess(responseObject as NSDictionary!)
            },
            failure: { (operation: AFHTTPRequestOperation!,
                error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                self.loading!.text = "Internet appears down!"
            })
    }
    
    func updateUISuccess(jsonResult: NSDictionary!) {
        self.loading!.text = nil
        self.loadingIndicator!.hidden = true
        self.loadingIndicator!.stopAnimating()
        
        if let tempResult = (jsonResult["main"]?["temp"]? as? Double) {
            
            // If we can get the temperature from JSON correctly, we assume the rest of JSON is correct.
            var temperature: Double
            if (jsonResult["sys"]?["country"]? as String == "US") {
                // Convert temperature to Fahrenheit if user is within the US
                temperature = round(((tempResult - 273.15) * 1.8) + 32)
            }
            else {
                // Otherwise, convert temperature to Celsius
                temperature = round(tempResult - 273.15)
            }
            // Is it a bug of Xcode 6? can not set the font size in IB.
            self.temperature!.font = UIFont.boldSystemFontOfSize(60)
            self.temperature!.text = "\(temperature)°"
            
            var name = jsonResult["name"]? as String
            self.location!.font = UIFont.boldSystemFontOfSize(25)
            self.location!.text = "\(name)"
            
            var condition = (jsonResult["weather"]? as NSArray)[0]?["id"]? as Int
            var sunrise = jsonResult["sys"]?["sunrise"]? as Double
            var sunset = jsonResult["sys"]?["sunset"]? as Double
            
            var nightTime = false
            var now = NSDate().timeIntervalSince1970
            // println(nowAsLong)
            
            if (now < sunrise || now > sunset) {
                nightTime = true
            }
            self.updateWeatherIcon(condition, nightTime: nightTime)
        }
        else {
            self.loading!.text = "Weather info is not available!"
        }
    }
    
    // Converts a Weather Condition into one of our icons.
    // Refer to: http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes
    func updateWeatherIcon(condition: Int, nightTime: Bool) {
        // Thunderstorm
        if (condition < 300) {
            if nightTime {
                self.icon!.image = UIImage(named: "tstorm1_night")
            } else {
                self.icon!.image = UIImage(named: "tstorm1")
            }
        }
            // Drizzle
        else if (condition < 500) {
            self.icon!.image = UIImage(named: "light_rain")
        }
            // Rain / Freezing rain / Shower rain
        else if (condition < 600) {
            self.icon!.image = UIImage(named: "shower3")
        }
            // Snow
        else if (condition < 700) {
            self.icon!.image = UIImage(named: "snow4")
        }
            // Fog / Mist / Haze / etc.
        else if (condition < 771) {
            if nightTime {
                self.icon!.image = UIImage(named: "fog_night")
            } else {
                self.icon!.image = UIImage(named: "fog")
            }
        }
            // Tornado / Squalls
        else if (condition < 800) {
            self.icon!.image = UIImage(named: "tstorm3")
        }
            // Sky is clear
        else if (condition == 800) {
            if (nightTime){
                self.icon!.image = UIImage(named: "sunny_night") // sunny night?
            }
            else {
                self.icon!.image = UIImage(named: "sunny")
            }
        }
            // few / scattered / broken clouds
        else if (condition < 804) {
            if (nightTime){
                self.icon!.image = UIImage(named: "cloudy2_night")
            }
            else{
                self.icon!.image = UIImage(named: "cloudy2")
            }
        }
            // overcast clouds
        else if (condition == 804) {
            self.icon!.image = UIImage(named: "overcast")
        }
            // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)) {
            self.icon!.image = UIImage(named: "tstorm3")
        }
            // Cold
        else if (condition == 903) {
            self.icon!.image = UIImage(named: "snow5")
        }
            // Hot
        else if (condition == 904) {
            self.icon!.image = UIImage(named: "sunny")
        }
            // Weather condition is not available
        else {
            self.icon!.image = UIImage(named: "dunno")
        }
    }
    
    /*
    func finishLaunch() {
    //ask for authorization
    let status = CLLocationManager.authorizationStatus()
    if(status == CLAuthorizationStatus.NotDetermined) {
    self.locationManager.requestAlwaysAuthorization();
    }
    else {
    locationManager.startUpdatingLocation()
    }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    if(status == CLAuthorizationStatus.NotDetermined) {
    println("Auth status unkown still!");
    }
    locationManager.startUpdatingLocation()
    }
    */
    
    /*
    iOS 8 Utility
    */
    func ios8() -> Bool {
        println("iOS " + UIDevice.currentDevice().systemVersion)
        // There is a problem if Apple upgrades iOS version to 8.1 or something else.
        if ( UIDevice.currentDevice().systemVersion == "8.0" ) {
            return true
        } else {
            return false
        }
    }
    
    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]!) {
        var location:CLLocation = locations[locations.count-1] as CLLocation
        
        if (location.horizontalAccuracy > 0) {
            self.locationManager.stopUpdatingLocation()
            println(location.coordinate)
            updateWeatherInfo(location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
       self.loading!.text = "Can't get your location!"
    }
}