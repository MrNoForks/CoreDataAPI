//
//  Photo+CoreDataProperties.swift
//  CoreDataAPI
//
//  Created by Boppo Technologies on 17/06/19.
//  Copyright © 2019 Boppo Technologies. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var author: String?
    @NSManaged public var mediaURL: String?
    @NSManaged public var tags: String?

}
