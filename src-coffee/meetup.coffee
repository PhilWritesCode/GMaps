meetupApp = angular.module 'meetupApp', ['AngularGM','ngGPlaces']

meetupApp.factory 'locationService', ->
    @geocoder = new google.maps.Geocoder();

    @processLocation = (newLocation, addLocation) =>
        @geocoder.geocode {address: newLocation}, (results, status) ->
            if status == google.maps.GeocoderStatus.OK
                addLocation(results[0])
            else
                alert("Failed!  Status: " + status)

    {@processLocation}


meetupApp.controller 'MeetupController', ($scope,ngGPlacesAPI, locationService) ->
	@products = gems
	@locations = []
	@bounds = new google.maps.LatLngBounds()
	@mapCenter
	@mapCenterVisible = false
	@searchResults
	@formEntry
	@usedEntries = []

	@processFormEntry = ->
        if @formEntry && @formEntry not in @usedEntries
            locationService.processLocation @formEntry, @addLocation
            @usedEntries.push @formEntry
        @formEntry = ""

	@addLocation = (newLocation) =>
		@locations.push(newLocation)
		@updateBounds()
		console.log @bounds.toString()
		@mapCenter = @bounds.getCenter()
		@mapCenterOptions.visible = @locations.length > 1

		$scope.$broadcast('gmMapResize', 'simpleMap')
		$scope.$apply()

	@updateBounds = =>
		@bounds = new google.maps.LatLngBounds()
		for location in @locations
			@bounds.extend(location.geometry.location)

	@mapOptions = {map: {center: new google.maps.LatLng(39, -95),zoom: 4,mapTypeId: google.maps.MapTypeId.TERRAIN}};
	@mapCenterOptions = {draggable: true, visible: false, icon:"https://maps.google.com/mapfiles/ms/icons/green-dot.png"}
	@searchResultOptions = {draggable: false, icon:"https://maps.google.com/mapfiles/ms/icons/yellow-dot.png"}






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
