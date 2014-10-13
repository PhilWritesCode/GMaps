meetupApp = angular.module 'meetupApp', ['AngularGM','ngGPlaces']

meetupApp.factory 'locationService', ->
	@geocoder = new google.maps.Geocoder()
	@searcher = new google.maps.places.PlacesService document.getElementById 'results'

	@processLocation = (newLocation, centerOfSearchArea, addLocation) =>
		@geocoder.geocode {address: newLocation, location: centerOfSearchArea}, (results, status) ->
			if status == google.maps.GeocoderStatus.OK
				addLocation results[0]
			else
				alert("Failed!  Status: " + status)

	@performSearch = (searchArea, searchTerm, displayResults) =>
		@searcher.textSearch {query : searchTerm, location : searchArea, radius: 5},(results, status, pagination) ->
			console.log("callback!");
			if status == google.maps.places.PlacesServiceStatus.ZERO_RESULTS
				alert 'No results!'
				return
			displayResults results, pagination

	@getLocationDetails = (locationReferenceId, addLocationDetails) =>
		@searcher.getDetails {placeId : locationReferenceId},(place, status) ->
			if status != google.maps.places.PlacesServiceStatus.OK
				alert 'Detail error!'
				return
			addLocationDetails place

	{@processLocation, @performSearch, @getLocationDetails}


meetupApp.controller 'MeetupController', ($scope,ngGPlacesAPI, locationService) ->
	@locationMarkers = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
	@clickDisablingNodes = ['SELECT', 'A', 'INPUT']
	@locations = []
	@bounds = new google.maps.LatLngBounds()
	@centerOfSearchArea
	@formEntry
	@searchTerm = "coffee"
	@markerEvents
	@searchPages = []
	@searchPageIndex = 0
	@searchPaginationObject

	@test = ->
		console.log("test executed")

	@processFormEntry = ->
		if @formEntry
			locationService.processLocation @formEntry, @centerOfSearchArea, @addLocation
		@formEntry = ""

	@locationAlreadyEntered = (locationToCheck) ->
		for location in @locations
			if location.formatted_address == locationToCheck.formatted_address
				return true
		return false

	@addLocation = (newLocation) =>
		if !@locationAlreadyEntered newLocation
			@locations.push newLocation
			@updateMapLocations()
			@performSearch()
			$scope.$apply()

	@removeLocation = (locationToRemove) ->
		@locations.splice @locations.indexOf(locationToRemove), 1
		@updateMapLocations()
		@performSearch()

	@updateMapLocations = =>
		if @locations.length > 0
			@bounds = new google.maps.LatLngBounds()
			for location in @locations
				@bounds.extend location.geometry.location
		@centerOfSearchArea = @bounds.getCenter()

	@updateMapSearchResults = =>
		if @getDisplayedResults().length > 0
			@bounds = new google.maps.LatLngBounds()
			for location in @locations
				@bounds.extend location.geometry.location
			for result in @getDisplayedResults()
				@bounds.extend result.geometry.location

	@updateSearchArea = (object, marker) ->
		@centerOfSearchArea = marker.getPosition()
		@performSearch()

	@performSearch = =>
		@searchPages = []
		@searchPageIndex = 0
		if !@searchTerm || @locations.length == 0
			return
		locationService.performSearch @centerOfSearchArea, @searchTerm, @displayResults

	@displayResults = (results, pagination) =>
		@searchPaginationObject = pagination
		@searchPages.push results.slice(0,10)
		@searchPages.push results.slice(10)
		if @searchPages.length > 2
			@searchPageIndex++
		@updateMapSearchResults()
		$scope.$apply()

	@getDisplayedResults = ->
		return @searchPages[@searchPageIndex]

	@addLocationDetail = (place) =>
		for result in @getDisplayedResults()
			if result.place_id == place.place_id
				result.reviews = place.reviews
				result.formatted_phone_number = place.formatted_phone_number
				result.url = place.url
				result.website = place.website
				result.opening_hours = place.opening_hours
				break;
		$scope.$apply()
		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

	@getMapLocationOptions = (result) ->
		angular.extend( @mapLocationOptions,
			{icon: "http://maps.google.com/mapfiles/marker_grey" + @locationMarkers[@locations.indexOf(result)] + ".png"}
		)

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

	@getLocationId = (location) ->
		@locationMarkers[@locations.indexOf location]

	@getBaseUrl = (fullUrl) ->
		if(fullUrl)
			urlParts = fullUrl.split '/'
			urlParts[2]

	@getHoursForToday = (result) ->
		dayIndex = new Date().getDay()
		if result.opening_hours && result.opening_hours.periods
			currentPeriod = result.opening_hours.periods[dayIndex]
			if currentPeriod
				open = @formatHours(currentPeriod.open.hours) + ':' + @formatMinutes(currentPeriod.open.minutes) + " " + @getAMPM(currentPeriod.open.hours)
				close = @formatHours(currentPeriod.close.hours) + ':' + @formatMinutes(currentPeriod.close.minutes) + " " + @getAMPM(currentPeriod.close.hours)
				return open + " - " + close
			else
				return "Closed"

	@formatHours = (rawHours) ->
		if rawHours < 13
			return rawHours
		else
			return rawHours - 12

	@formatMinutes = (rawMinutes) ->
		if rawMinutes > 10
			return rawMinutes
		else
			return rawMinutes + "0"

	@getAMPM = (rawHours) ->
		if rawHours < 12
			return "am"
		else
			return "pm"

	@selectResult = (thisResult) ->
		if(thisResult.website == undefined)
			locationService.getLocationDetails thisResult.place_id, @addLocationDetail
		for result in @getDisplayedResults()
			result.selected = false
		thisResult.selected = true
		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

	@deSelectResult = (thisResult) ->
		thisResult.selected = false
		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

	@highlightResult = (result) ->
    		result.highlighted = true
    		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

	@unHighlightResult = (result) ->
    		result.highlighted = false
    		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

	@toggleSelection = (result) ->
		if result.selected
			@deSelectResult result
			@triggerCloseInfoWindow result
		else
			@selectResult result
			@triggerOpenInfoWindow result

	@handleTextEntryClicked = (result, event) ->
		if event.target.nodeName in @clickDisablingNodes
		else
			@toggleSelection(result)

	@getDirections = (fromLocation, toLocation) ->
		console.log("from " + fromLocation + " to " + toLocation)
		if fromLocation && toLocation
			link = "http://maps.google.com/maps?saddr=" + fromLocation.formatted_address + "&daddr=" +  toLocation.formatted_address
			console.log(link)
			window.open(link, "_blank");
		return true

	@triggerOpenInfoWindow = (result) ->
    		@markerEvents = [{event: 'openinfowindow',ids: ['result' + result.formatted_address]}];

	@triggerCloseInfoWindow = (result) ->
    		@markerEvents = [{event: 'closeinfowindow',ids: ['result' + result.formatted_address]}];

	@getNormalizedAddress = (location) ->
		if location
			address = location.formatted_address
			if address.indexOf(", USA") > 0
				return address.substr(0, address.indexOf(", USA"))
			else if address.indexOf(", United States") > 0
				return address.substr(0, address.indexOf(", United States"))
			else
				return address

	@nextPageAvailable = ->
		@searchPages.length-1 > @searchPageIndex || (@searchPaginationObject &&@searchPaginationObject.hasNextPage)

	@getSearchResultPageNumbers = ->
		if @getDisplayedResults()
			(@searchPageIndex * 10 + 1) + " - " + (@searchPageIndex * 10 + @getDisplayedResults().length)

	@getPreviousPage = ->
		if @searchPageIndex > 0
			@searchPageIndex--
			@updateMapSearchResults()

	@getNextPage = ->
		if @searchPages.length-1 > @searchPageIndex
			@searchPageIndex++
			@updateMapSearchResults()
		else if @searchPaginationObject.hasNextPage
			@searchPaginationObject.nextPage()

	@markerSelectedIcon = {icon: 'https://maps.gstatic.com/mapfiles/ms2/micons/yellow-dot.png'}
	@markerHighlightedIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_yellow.png'}
	@markerDefaultIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_purple.png'}

	@mapOptions = {map: {center: new google.maps.LatLng(39, -95),zoom: 4,mapTypeId: google.maps.MapTypeId.TERRAIN}};
	@mapSearchAreaOptions = {visible: true; draggable: true, icon:"http://maps.google.com/mapfiles/arrow.png"}
	@mapLocationOptions = {draggable: false}
	@searchResultOptions = {draggable: false, clickable: true}
	@mapHiddenMarkersOptions = {visible: false}

