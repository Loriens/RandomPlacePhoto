//
//  Localizable.swift
//  RandomPlacePhoto
//
//  Created by Vladislav on 12/08/2019.
//  Copyright © 2019 Vladislav Markov. All rights reserved.
//

import Foundation

protocol Localizable: RawRepresentable { }

extension Localizable {
    
    var key: String {
        return rawValue as? String ?? ""
    }
    
    var localized: String {
        let lang: String = AppLocalizationManager.current.type.localizationKey
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let bundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
        } else {
            return NSLocalizedString(key, comment: "")
        }
    }
}
