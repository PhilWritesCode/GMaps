meetupApp = angular.module 'meetupApp', ['AngularGM','ngGPlaces']

meetupApp.factory 'locationService', ->
	@geocoder = new google.maps.Geocoder()
	@searcher = new google.maps.places.PlacesService document.getElementById 'results'

	@processLocation = (newLocation, startingLocation, addLocation) =>
		@geocoder.geocode {address: newLocation, location: startingLocation}, (results, status) ->
			if status == google.maps.GeocoderStatus.OK
				addLocation results[0]
			else
				alert("Failed!  Status: " + status)

	@performSearch = (searchArea, searchTerm, displayResults) =>
		@searcher.textSearch {query : searchTerm, location : searchArea, radius: 5},(results, status, pagination) ->
			if status == google.maps.places.PlacesServiceStatus.ZERO_RESULTS
				alert 'No results!'
				return
			displayResults results

	{@processLocation, @performSearch}


meetupApp.controller 'MeetupController', ($scope,ngGPlacesAPI, locationService) ->
	@products = gems
	@locations = []
	@bounds = new google.maps.LatLngBounds()
	@centerOfSearchArea
	@searchResults
	@formEntry
	@usedEntries = []
	@searchTerm = "coffee"
	@searchResults

	@processFormEntry = ->
		if @formEntry && @formEntry not in @usedEntries
			locationService.processLocation @formEntry, @centerOfSearchArea, @addLocation
			@usedEntries.push @formEntry
		@formEntry = ""

	@addLocation = (newLocation) =>
		@locations.push newLocation
		@updateMap()
		@performSearch()
		$scope.$apply()

	@removeLocation = (locationToRemove) ->
		@locations.pop locationToRemove
		@usedEntries.pop locationToRemove
		@updateMap()
		@performSearch()

	@updateMap = =>
		if @locations.length > 0
			@bounds = new google.maps.LatLngBounds()
			for location in @locations
				@bounds.extend location.geometry.location
			@centerOfSearchArea = @bounds.getCenter()
		else
			@centerOfSearchArea = null

	@updateSearchArea = (object, marker) ->
		@centerOfSearchArea = marker.getPosition()
		@performSearch()

	@performSearch = =>
		if !@searchTerm || @locations.length == 0
			@searchResults = []
			return
		locationService.performSearch @centerOfSearchArea, @searchTerm, @displayResults

	@displayResults = (results) =>
		@searchResults = results.slice(0,10)
		$scope.$apply()


	@mapOptions = {map: {center: new google.maps.LatLng(39, -95),zoom: 4,mapTypeId: google.maps.MapTypeId.TERRAIN}};
	@mapSearchAreaOptions = {draggable: true, icon:"https://maps.google.com/mapfiles/ms/icons/green-dot.png"}
	@mapLocationOptions = {draggable: true, icon:"https://maps.google.com/mapfiles/ms/icons/blue-dot.png"}
	@searchResultOptions = {draggable: false, clickable: true, icon:"https://maps.google.com/mapfiles/ms/icons/yellow-dot.png"}












gems = [
	{name: 'Dodecahedron', price: 2.95, description: 'Here is some nonsensical description text', reviews:[], canPurchase: true, soldOut: true},
	{name: 'Pentagonal Gem', price: 5.95, description: 'Different descriptive text', reviews:[], canPurchase: true, soldOut: false},
	{name: 'Something new', price: 4.95, description: 'Poo dollar',reviews: [{stars:5, body:"I love this product!", author: "phil@shutterfly.com"}], canPurchase: true, soldOut: false},
]

meetupApp.controller 'PanelController', ->
	@tab = 1
	@selectTab = (setTab) ->
		@tab = setTab
	@isSelected = (checkTab) ->
		@tab == checkTab

meetupApp.controller 'ReviewController', ->
	@review = {}
	@addReview = (address) ->
		address.reviews.push(@review)
		@review = {}
