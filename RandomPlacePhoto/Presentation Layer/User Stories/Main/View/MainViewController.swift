//
//  MainViewController.swift
//  RandomPlacePhoto
//
//  Created by Vladislav on 13/08/2019.
//  Copyright © 2019 Vladislav Markov. All rights reserved.
//

import UIKit
import Kingfisher

// TODO: - Сделать красивую кнопку настроек
class MainViewController: UIViewController, MainViewInput {

    // MARK: - Outlets
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var cityNameLabel: UILabel!
    @IBOutlet private weak var nextCityButton: UIButton!
    
    // MARK: - Props
    var output: MainViewOutput?
    
    private var removedView: UIView?
    private var photosURLs: [URL] = []
    private var photosImageViews: [UIImageView] = []
    private var loader: Loader?
    
    private var blockNextButtonTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader = Loader(view: view)
        loadData()
        
        setupComponents()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        applyStyles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        blockNextButtonTimer?.fire()
        blockNextButtonTimer = nil
    }
    
    // MARK: - Setup functions
    func setupComponents() {
        view.backgroundColor = AppTheme.backgroundMain
        nextCityButton.setTitle(AppLocalization.General.next.localized, for: .normal)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: AppAssets.humburgerMenu, style: .plain, target: self, action: #selector(showSettings))
    }
    
    func setupActions() {
        nextCityButton.addTarget(self, action: #selector(nextButtonPressed), for: .touchUpInside)
    }
    
    func applyStyles() {
        cityNameLabel.apply(.bigTitleStyle())
        infoView.apply(.infoStyle())
        nextCityButton.apply(.accentMainStyle())
    }
    
    // MARK: - MainViewInput
    func updateCity(with city: City) {
        DispatchQueue.main.async {
            self.cityNameLabel.text = city.name
        }
    }
    
    func updatePhotoSlider(with photos: [URL]) {
        photosURLs = photos
        photosImageViews = []
        
        addPhotos()
    }
    
    func loadDataError() {
        loader?.hide()
    }
    
}

// MARK: - Actions
extension MainViewController {
    
    @objc
    func showSettings() {
        output?.showSettings()
    }
    
    @objc
    func imageViewPanGestureHandler(recognizer: UIPanGestureRecognizer) {
        let screenWidth = UIScreen.main.bounds.width
        let translationX = recognizer.translation(in: view).x
        let translationY = recognizer.translation(in: view).y
        let velocity: CGPoint = recognizer.velocity(in: view)
        let hypotenuseVelocity: CGFloat = hypot(velocity.x, velocity.y)
        
        if (abs(translationX) > screenWidth / 2 || hypotenuseVelocity > 1000.0) && recognizer.state == .ended {
            UIView.animate(withDuration: 0.5, animations: {
                recognizer.view?.center.x += translationX > 0 ? screenWidth : -screenWidth
                recognizer.view?.center.y += translationY
            }) { _ in
                recognizer.view?.removeFromSuperview()
            }
            
            guard let view = recognizer.view as? UIImageView,
                photosImageViews.contains(view) else {
                    clearData()
                    loadData()
                    return
            }
            photosImageViews.removeAll(where: { $0 == view })
            
            if photosImageViews.isEmpty {
                loadData()
            }
        } else if recognizer.state == .ended {
            UIView.animate(withDuration: 0.2, animations: {
                recognizer.view?.center = self.view.center
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                recognizer.view?.center.x = self.view.center.x + translationX
                recognizer.view?.center.y = self.view.center.y + translationY
            })
        }
    }
    
    @objc
    private func nextButtonPressed() {
        clearData()
        loadData()
        blockNextButton()
        blockNextButtonTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] _ in
            self?.unblockNextButton()
        })
    }
    
    @objc
    private func imageViewTapGestureHandler(_ recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view as? UIImageView,
            let image = view.image else { return }
        
        output?.selectImage(with: image)
    }
    
}

// MARK: - Module functions
extension MainViewController {
    
    func loadData() {
        loader?.show()
        output?.loadData()
    }
    
    func addPhotos() {
        while !photosURLs.isEmpty {
            let url = photosURLs.removeFirst()
            
            DispatchQueue.main.async { [weak self] in
                guard let imageView = self?.createImageViewForPhoto() else { return }
                
                imageView.kf.setImage(with: url) { _ in
                    imageView.setNeedsDisplay()
                    imageView.frame = imageView.getScaledImageSize() ?? CGRect(x: 0, y: 0, width: 0, height: 0)
                    imageView.apply(.roundedStyle())
                }
            }
        }
        
        loader?.hide()
    }
    
    private func createImageViewForPhoto() -> UIImageView {
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        
        view.insertSubview(imageView, at: 0)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.imageViewPanGestureHandler))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewTapGestureHandler))
        tapGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.addGestureRecognizer(panGestureRecognizer)
        photosImageViews.append(imageView)
        
        return imageView
    }
    
    private func clearData() {
        for imageView in photosImageViews {
            imageView.removeFromSuperview()
        }
        for view in view.subviews where view is UIImageView {
            view.removeFromSuperview()
        }
        photosImageViews = []
    }
    
    private func displayShareSheet() {
        let activityViewController = UIActivityViewController(activityItems: ["dsfs" as NSString], applicationActivities: nil)
        navigationController?.present(activityViewController, animated: true, completion: nil)
    }
    
    private func blockNextButton() {
        DispatchQueue.main.async {
            self.nextCityButton.isEnabled = false
            self.nextCityButton.alpha = 0.5
        }
    }
    
    private func unblockNextButton() {
        DispatchQueue.main.async {
            self.nextCityButton.isEnabled = true
            self.nextCityButton.alpha = 1.0
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension MainViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
    
}
