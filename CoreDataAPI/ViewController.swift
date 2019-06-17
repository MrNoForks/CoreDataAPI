//
//  ViewController.swift
//  CoreDataAPI
//
//  Created by Boppo Technologies on 17/06/19.
//  Copyright © 2019 Boppo Technologies. All rights reserved.
//
//https://medium.com/@jamesrochabrun/parsing-json-response-and-save-it-in-coredata-step-by-step-fb58fc6ce16f
import UIKit
import CoreData
class ViewController : UITableViewController {
    
    let colorDict : [Int : UIColor] = [0 : #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) , 1 : #colorLiteral(red: 1, green: 0.2072239737, blue: 0.1368105647, alpha: 1) , 2 : #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)]
    
    let query = "dogs"
    
    lazy var endPoint: String = { return "https://api.flickr.com/services/feeds/photos_public.gne?format=json&tags=\(self.query)&nojsoncallback=1#" }()
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        //cell.imageView1.backgroundColor = colorDict[indexPath.row]
        if let photo = fetchedhResultController.object(at: indexPath) as? Photo {
          //  cell.imageView1.image =
            cell.setPhotoCellWith(photo: photo)
        }
        return cell
    }
    
    override func viewDidLoad() {
        print("hi")
        getDataWith { (result) in
            switch result{
            case .Success(let data):
                print(data)
                self.clearData()
                self.saveInCoreDataWith(array: data)
            case .Error(let message):
                DispatchQueue.main.async {
                    self.showAlertWith(title: "Error", message: message)
                }
            }
        }
        
        
        do {
            try self.fetchedhResultController.performFetch()
            print("COUNT FETCHED FIRST: \(self.fetchedhResultController.sections?[0].numberOfObjects)")
        } catch let error  {
            print("ERROR: \(error)")
        }
    }
    
    
    enum Result <T>{
        case Success(T)
        case Error(String)
    }
    
    
    
    
    
    func getDataWith(completion: @escaping (Result<[[String: AnyObject]]>) -> Void) {
        
        guard let url = URL(string: endPoint)  else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else{ return}
            do{
                if  let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers] ) as? [String : AnyObject]{
                    guard let itemJsonArray = json["items"] as? [[String : AnyObject]] else {return}
                    DispatchQueue.main.async {
                        completion(.Success(itemJsonArray))
                    }
                    
                }

            }
            catch let error{
                completion(.Error(error.localizedDescription))
            }
            
        }.resume()
        
        
    }
    
    
    func showAlertWith(title: String, message: String, style: UIAlertController.Style = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //       // return view.frame.width + 500
    //    }
    
    
    
    
    private func createPhotoEntityFrom(dictionary: [String: AnyObject]) -> NSManagedObject? {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        
        if let photoEntity = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as? Photo {
            photoEntity.author = dictionary["author"] as? String
            photoEntity.tags = dictionary["tags"] as? String
            let mediaDictionary = dictionary["media"] as? [String: AnyObject]
            photoEntity.mediaURL = mediaDictionary?["m"] as? String
            return photoEntity
        }
        return nil
    }
    
    private func saveInCoreDataWith(array: [[String: AnyObject]]) {
        _ = array.map{self.createPhotoEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.shared.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    lazy var fetchedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Photo.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "author", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        // frc.delegate = self
        return frc
    }()
    
    private func clearData() {
        do {
            let context = CoreDataStack.shared.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            do {
                let objects  = try context.fetch(fetchRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                CoreDataStack.shared.saveContext()
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
        }
    }
}

