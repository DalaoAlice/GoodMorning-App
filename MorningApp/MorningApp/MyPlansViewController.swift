//
//  MyPlansViewController.swift
//  MorningApp
//
//  Created by 刘涵 on 2017/8/2.
//  Copyright © 2017年 刘涵. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class MyPlansViewController:UIViewController, CLLocationManagerDelegate{
    

    var timer = Timer()
    
    //定位相关
    let locationMgr:CLLocationManager=CLLocationManager()
    let geocoder=CLGeocoder()
    
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var citynameLabel: UILabel!
    

    
    func updateTime () {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        dateLabel.text = String(year)+"."+String(month)+"."+String(day)
       // totalTimeLabel.text = String(AddTaskViewController.totaltime)
        
        
        hourLabel.text = String(hour)
        minuteLabel.text = String(minutes)
        secondLabel.text = String(seconds)
        
        
        
    }
        override func viewDidLoad() {
        super.viewDidLoad()
        updateTime()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            
        }
              _ = Timer.scheduledTimer(timeInterval: 1, target:self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
            totalTimeLabel.text = String(NewPlanViewController.newtime)
           //getWeather(city:"Beijing")
            StartLocating() //And the function will call getWeather()
    }
  


func getWeather(city: String) {
    
    let urlString = URL(string: "http://api.openweathermap.org/data/2.5/weather?q=\(String(describing: city))&units=metric&APPID=c10457489be06fbf428dbbb32ac7216a")
    
    // if it failed
    if urlString==nil{
        print("urlString is nil, means ALL IS OVER! TAT")
        self.temperatureLabel.text = "Failed to get weather. orz"
        self.descriptionLabel.text = "You can try other apps :)"
        self.citynameLabel.text=city    // Fortunately, at least we know where we are :)
                                        //(maybe...)
    }
    
    // setup a "URL session" that handles the data that comes back from the api call
    else{
    let task = URLSession.shared.dataTask(with: urlString!) { (data, response, error) in
        do {
            if let data = data,
                
                //translate the data into a JSON object
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print(json) //print the entire json object retrieved from the url string
                
                //the following code parses through the JSON object, you can experiment here and try to print and get different values from the JSON object
                let main = json["main"] as! [String : Any]
                print(main)
                let wea = json["weather"] as! [Any]
                let temp2 = wea[0]
                let finalDictionary = temp2 as! [String : Any]
                let des = finalDictionary["description"] as! String
                
                let temp = main["temp"] as! Int
                print(temp)
                print(des)
                
                //once you have collected the data you need, you can now update any UI objects on your view controller
                DispatchQueue.main.async {
                    
                    self.temperatureLabel.text = String(temp) + "℃"
                    self.descriptionLabel.text = des
                    //self.citynameLabel.text = "Beijing"
                    self.citynameLabel.text=city //
                    
                }
                
            }
        }catch {
            print("Error deserializing JSON: \(error)")
        }
    }
    task.resume()
    }
    }
    
    
    public func StartLocating()
    {
        locationMgr.delegate=self
        locationMgr.requestWhenInUseAuthorization() // 弹出用户授权对话框，使用程序期间授权（ios8后)
        //locationMgr.requestAlwaysAuthorization()  // 类似上面
        locationMgr.startUpdatingLocation()
        print("开始定位")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // 大概就是定位成功后的回调函数
        
        guard let location:CLLocation = locations.last else {return} // 获取最后一个位置的坐标
        //let newLocation = CLLocation(latitude: 32.029171, longitude: 118.788231) // debug
        print(location)
        
        //语言强制转成英文，方便一会获取英文地名
        let myLangArray = NSArray(object: "en-US")
        var langArray:NSArray = UserDefaults.standard.object(forKey:"AppleLanguages") as! NSArray // 保存当前语言设置，方便换回来
        print ("Current langueges:\(langArray)") // debug
        UserDefaults.standard.set(myLangArray, forKey: "AppleLanguages") // 切换语言，注意这是一个数组

        // 地理信息反编码，也就是坐标->地名
        // 苹果自带的反编码，中国服务商是高德，因此目前只能解决国内地名（还有少部分有格式问题）……
        // 这应该是个TODO，要不换天气，API要不换解码器，要不换更聪明的程序员……
        geocoder.reverseGeocodeLocation(location, completionHandler: {
            // 注意这个代码块，没理解错的话定义的是completionHandler，是一个回调函数，因此要注意运行顺序
            
            (placemarks:[CLPlacemark]?, error:Error?) -> Void in // 解包
            var city:String="Beijing" // 默认北京，北京是个好地方
            
            if error != nil {
                print( "OH NO!!!!! failed to reverse\n\(String(describing: error))" ) // 这里注意，OH NO是一个JoJo梗
            }
                
            else{
            if let p = placemarks?[0]{
                print(p) // 输出反编码信息
                
                // 接下来是最开心的获取城市名部分
                if let locality = p.locality {
                    print(locality)
                    city=locality
                }
                else{
                    print("no locality")
                    if let administrativeArea = p.administrativeArea {
                        print(administrativeArea)
                        city=administrativeArea
                    }
                    else{
                        print("no administrativeArea")
                        city = p.country!
                    }
                    
                }
                self.getWeather(city: city) // 递交处理结果

            }
                
            //将语言切换回原设置，注意由于这是个回调函数，所以必须写在这里而不是locationManager()里
            UserDefaults.standard.set(langArray, forKey: "AppleLanguages")
            langArray = UserDefaults.standard.object(forKey:"AppleLanguages") as! NSArray
            print ("Then current langueges:\(langArray)")
            }
        })
        manager.stopUpdatingLocation() // 结束定位
    }

}
