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
	@locations = []
	@bounds = new google.maps.LatLngBounds()
	@centerOfSearchArea
	@searchResults
	@formEntry
	@usedEntries = []
	@searchTerm = "coffee"
	@searchResults
	@markerEvents

	@processFormEntry = ->
		if @formEntry && @formEntry not in @usedEntries
			locationService.processLocation @formEntry, @centerOfSearchArea, @addLocation
			@usedEntries.push @formEntry
		@formEntry = ""

	@addLocation = (newLocation) =>
		@locations.push newLocation
		@updateMapLocations()
		@performSearch()
		$scope.$apply()

	@removeLocation = (locationToRemove) ->
		@locations.pop locationToRemove
		@usedEntries.pop locationToRemove
		@updateMapLocations()
		@performSearch()

	@updateMapLocations = =>
		if @locations.length > 0
			@bounds = new google.maps.LatLngBounds()
			for location in @locations
				@bounds.extend location.geometry.location
		@centerOfSearchArea = @bounds.getCenter()

	@updateMapSearchResults = =>
		if@searchResults.length > 0
			@bounds = new google.maps.LatLngBounds()
			for location in @locations
				@bounds.extend location.geometry.location
			for result in @searchResults
				@bounds.extend result.geometry.location

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
		@updateMapSearchResults()
		$scope.$apply()

	@getMapSearchAreaOptions = ->
		if @locations.length > 0
			return @mapSearchAreaOptions
		else
			return @mapHiddenMarkersOptions

	@getMapSearchResultsOptions = (result) ->
		angular.extend( @searchResultOptions,
			if result.selected
				@markerSelectedIcon
			else if result.highlighted
				@markerHighlightedIcon
			else
				@markerDefaultIcon
		)

	@selectResult = (thisResult) ->
		for result in @searchResults
			result.selected = false
		thisResult.selected = true
		$scope.$broadcast('gmMarkersUpdate', 'meetup.searchResults');

	@deSelectResult = (thisResult) ->
		thisResult.selected = false
		$scope.$broadcast('gmMarkersUpdate', 'meetup.searchResults');


	@highlightResult = (result) ->
    		result.highlighted = true
    		$scope.$broadcast('gmMarkersUpdate', 'meetup.searchResults');

	@unHighlightResult = (result) ->
    		result.highlighted = false
    		$scope.$broadcast('gmMarkersUpdate', 'meetup.searchResults');

	@toggleSelection = (result) ->
		if result.selected
			@deSelectResult result
			@triggerCloseInfoWindow result
		else
			@selectResult result
			@triggerOpenInfoWindow result

	@triggerOpenInfoWindow = (result) ->
    		@markerEvents = [{event: 'openinfowindow',ids: ['result' + result.formatted_address]}];

	@triggerCloseInfoWindow = (result) ->
    		@markerEvents = [{event: 'closeinfowindow',ids: ['result' + result.formatted_address]}];


	@markerSelectedIcon = {icon: 'https://maps.gstatic.com/mapfiles/ms2/micons/yellow-dot.png'}
	@markerHighlightedIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_yellow.png'}
	@markerDefaultIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_purple.png'}

	@mapOptions = {map: {center: new google.maps.LatLng(39, -95),zoom: 4,mapTypeId: google.maps.MapTypeId.TERRAIN}};
	@mapSearchAreaOptions = {visible: true; draggable: true, icon:"http://maps.google.com/intl/en_us/mapfiles/ms/micons/green-dot.png"}
	@mapLocationOptions = {draggable: false, icon:"https://maps.google.com/mapfiles/ms/icons/blue-dot.png"}
	@searchResultOptions = {draggable: false, clickable: true}
	@mapHiddenMarkersOptions = {visible: false}
