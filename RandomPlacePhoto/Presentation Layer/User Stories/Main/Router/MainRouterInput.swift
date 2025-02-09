//
//  MainRouterInput.swift
//  RandomPlacePhoto
//
//  Created by Vladislav on 13/08/2019.
//  Copyright © 2019 Vladislav Markov. All rights reserved.
//

import UIKit

protocol MainRouterInput: class {
    func presentPhotoViewController(with image: UIImage?)
    func presentSettingsViewController()
}
