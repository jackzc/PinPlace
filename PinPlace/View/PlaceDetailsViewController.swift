//
//  PlaceDetailsViewController.swift
//  PinPlace
//
//  Created by Artem on 6/14/16.
//  Copyright © 2016 Artem. All rights reserved.
//

import UIKit
import PKHUD
import RxSwift
import RxCocoa

class PlaceDetailsViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet fileprivate weak var centerOnMapButton: UIButton!
    @IBOutlet fileprivate weak var buildRouteButton: UIButton!
    @IBOutlet fileprivate weak var loadNearbyPlacesButton: UIButton!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var trashBarButtonItem: UIBarButtonItem!
    
    var viewModel: PlaceDetailsViewModel?
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel?.place?.rx.observe(String.self, PlaceAttributes.title.rawValue).bindNext { [unowned self] newValue in
            self.navigationItem.title = newValue
            self.viewModel?.savePlaceTitle()
            }.addDisposableTo(disposeBag)
        
        loadNearbyPlacesButton.rx.tap.bindNext {[unowned self] in
            HUD.show(.progress)
            self.viewModel?.fetchNearbyPlaces() {
                HUD.flash(.success, delay: 1.0)
            }
            }.addDisposableTo(disposeBag)
        
        centerOnMapButton.rx.tap.bindNext { [unowned self] in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.CenterPlace.rawValue), object: self.viewModel?.place)
            self.navigationController?.popToRootViewController(animated: true)
        }.addDisposableTo(disposeBag)
        
        buildRouteButton.rx.tap.bindNext {[unowned self] in
            if let mapViewController = self.navigationController?.viewControllers.first as? PlacesMapViewController {
                mapViewController.viewModel.selectedTargetPlace = self.viewModel?.place
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.BuildRoute.rawValue), object: nil)
                self.navigationController?.popToRootViewController(animated: true)
            }
            }.addDisposableTo(disposeBag)
        
        trashBarButtonItem.rx.tap.bindNext { _ in
            let alertController = UIAlertController(title: "", message: "Delete this place?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
            alertController.addAction(cancelAction)
            
            let OKAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (action) in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.PlaceDeleted.rawValue), object: self.viewModel?.place)
                self.viewModel?.deletePlace()
                self.navigationController?.popViewController(animated: true)
            }
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true, completion: nil)
            }.addDisposableTo(disposeBag)

        viewModel?.nearbyVenues.asObservable()
            .bindTo(tableView.rx.items(cellIdentifier: "FoursquareVenueCellIdentifier")) { (index, venue, cell) in
                //cell!.textLabel?.text = venue.name
            }.disposed(by: disposeBag)


        tableView.rx.itemSelected.bindNext { [unowned self] selectedIndexPath in
            let selectedNearbyVenue = self.viewModel?.nearbyVenues.value[selectedIndexPath.row]
            self.viewModel?.place?.title = selectedNearbyVenue?.name
            }.addDisposableTo(disposeBag)
        
    }
    
}
