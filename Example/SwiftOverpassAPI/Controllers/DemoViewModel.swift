//
//  DemoViewModel.swift
//  SwiftOverpassAPI_Example
//
//  Created by Edward Samson on 10/8/19.
//  Copyright © 2019 Edward Samson. All rights reserved.
//

import MapKit
import SwiftOverpassAPI

class DemoViewModel {
	
	let demo: Demo // Contains Overpass query details
	let overpassClient: OPClient // The client for requesting/decoding Overpass data
	
	// Overpass request did start/finish
	var loadingStatusDidChangeTo: ((_ isLoading: Bool) -> Void)?
	
	var elements = [Int: OPElement]() // Elements returned by an Overpass request
	
	// Configures Overpass visualizations for mapKit display
	let mapViewModel = DemoMapViewModel()
	
	// Configures Overpass elements for tableView display
	lazy var tableViewModel: DemoTableViewModel = {
		let tableViewModel = DemoTableViewModel(demo: demo)
		tableViewModel.delegate = self
		return tableViewModel
	}()
	
	// DemoViewModel is initialized with an overpass client and a demo that contains specific Overpass query details.
	init(demo: Demo, overpassClient: OPClient) {
		self.demo = demo
		self.overpassClient = overpassClient
	}
	
	// Run the query generated by the demo
	func run() {
		
		// Set the laoding status to true
		loadingStatusDidChangeTo?(true)
		
		// The square geographic region in which results will be requested
		let region = demo.defaultRegion
		
		// Set the mapView to the correct region for displaying the query
		setVisualRegion(forQueryRegion: region)
		
		// Generate the overpass query from the demo
		let query = demo.generateQuery(forRegion: region)
		
		// Post the query to the Overpass endpoint. The endpoint will send a response containing the matching elements.
		overpassClient.fetchElements(query: query) { result in
			
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .success(let elements):
				
				// Store the decoded elements
				self.elements = elements
				
				// Use the tableViewModel to create cell view models for the returned elements
				self.tableViewModel.generateCellViewModels(forElements: elements)
				
				// Generate mapKit visualizations for the returned elements using a static visualization generator
				let visualizations = OPVisualizationGenerator
					.mapKitVisualizations(forElements: elements)
				
				// Add the generated visualizations to the mapView via the mapViewModel
				self.mapViewModel.addVisualizations(visualizations)
			}
			// Set the loading status to false
			self.loadingStatusDidChangeTo?(false)
		}
	}
	
	// Inset the query region to get the region that will be displayed on the mapView. This prevents query boundaries from being visible when the query results are first displayed.
	private func setVisualRegion(forQueryRegion region: MKCoordinateRegion) {
		let queryRect = region.toMKMapRect()
		let visualRect = queryRect.insetBy(dx: queryRect.width * 0.25, dy: queryRect.height * 0.25)
		let visualRegion = MKCoordinateRegion(visualRect)
		mapViewModel.region = visualRegion
	}
	
	func resetMapViewRegion() {
		setVisualRegion(forQueryRegion: demo.defaultRegion)
	}
}

extension DemoViewModel: DemoTableViewModelDelegate {
	
	// If the user selects a cell, center the mapView on that cell's element
	func didSelectCell(forElementWithId id: Int) {
		mapViewModel.centerMap(onVisualizationWithId: id)
		
		if let tags = elements[id]?.tags {
			print("Selected element with tags: \(tags)")
		}
        
        if let meta = elements[id]?.meta {
            print("Meta data: \(meta)")
        }
	}
}
