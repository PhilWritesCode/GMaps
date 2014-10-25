meetupApp = angular.module 'meetupApp', ['AngularGM','ngGPlaces','ngAutocomplete']

meetupApp.factory 'locationService', ->
	@geocoder = new google.maps.Geocoder()
	@searcher = new google.maps.places.PlacesService document.getElementById 'results'

	@processLocation = (newLocation, centerOfSearchArea, addLocation) =>
		@geocoder.geocode {address: newLocation, location: centerOfSearchArea}, (results, status) ->
			if status == google.maps.GeocoderStatus.OK
				addLocation results[0]
			else if status == google.maps.GeocoderStatus.ZERO_RESULTS
				alert "Location not found!  Please try again, or add a different location."
			else if status == google.maps.GeocoderStatus.OVER_QUERY_LIMIT
				alert "Website is over query limit.  Please contact me at philip.t.jenkins@gmail.com"
			else if status == google.maps.GeocoderStatus.REQUEST_DENIED
				alert "Request denied.  Please contact me at philip.t.jenkins@gmail.com"
			else
				alert "Unknown Error.  Please check your internet connection and try again."

	@performSearch = (searchArea, searchTerm, displayResults, onError) =>
		@searcher.textSearch {query : searchTerm, location : searchArea, radius: 5},(results, status, pagination) ->
			if status == google.maps.places.PlacesServiceStatus.OK
				displayResults results, pagination
			else if status == google.maps.places.PlacesServiceStatus.ZERO_RESULTS
				alert "No results found!  Please enter a different search term."
				onError()
			else if status == google.maps.places.PlacesServiceStatus.INVALID_REQUEST
				alert "Invalid request.  Please check search term and try again."
				onError()
			else if status == google.maps.places.PlacesServiceStatus.OVER_QUERY_LIMIT
				alert "Website is over query limit.  Please contact me at philip.t.jenkins@gmail.com"
				onError()
			else if status == google.maps.GeocoderStatus.REQUEST_DENIED
				alert "Request denied.  Please contact me at philip.t.jenkins@gmail.com"
				onError()
			else
				alert "Unknown Error.  Please check your internet connection and try again."
				onError()


	@getLocationDetails = (locationReferenceId, addLocationDetails) =>
		@searcher.getDetails {placeId : locationReferenceId},(place, status) ->
			if status != google.maps.places.PlacesServiceStatus.OK
				console.log "error fetching location details."
				return
			addLocationDetails place

	{@processLocation, @performSearch, @getLocationDetails}


meetupApp.controller 'MeetupController', ($scope, $location, $anchorScroll, locationService) ->
	@locationMarkers = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
	@clickDisablingNodes = ['SELECT', 'A', 'INPUT']
	@locations = []
	@bounds = new google.maps.LatLngBounds()
	@centerOfSearchArea
	@locationFormEntry
	@searchTerm = "coffee"
	@markerEvents
	@searchPages = []
	@searchPageIndex = 0
	@searchPaginationObject
	pendingLocations = []

	@processLocationFormEntry = ->
		if @locationFormEntry
			locationService.processLocation @locationFormEntry, @centerOfSearchArea, @addLocation
		@locationFormEntry = ""

	@addLocation = (newLocation) =>
		if !@locationAlreadyEntered newLocation
			@locations.push newLocation
			@updateMapLocations()
			@performSearch()
			$scope.$apply()

	processNextPendingLocation = =>
		@locationFormEntry = pendingLocations.pop()
		@processLocationFormEntry()

	@locationAlreadyEntered = (locationToCheck) ->
		for location in @locations
			if location.formatted_address == locationToCheck.formatted_address
				return true
		return false

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
			updateResultsMarkers()
			return
		locationService.performSearch @centerOfSearchArea, @searchTerm, @displayResults, updateResultsMarkers

	@displayResults = (results, pagination) =>
		@searchPaginationObject = pagination

		@searchPages.push results.slice(0,10)
		if results.length > 10
			@searchPages.push results.slice(10)

		if @searchPages.length > 2
			@searchPageIndex++

		@updateMapSearchResults()
		$scope.$apply()
		if(pendingLocations.length > 0)
			processNextPendingLocation();

	updateResultsMarkers = =>
		$scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');

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
		updateResultsMarkers()

	@getLocationId = (location) ->
		@locationMarkers[@locations.indexOf location]

	@getBaseUrl = (fullUrl) ->
		if(fullUrl)
			urlParts = fullUrl.split '/'
			urlParts[2]

	@selectResult = (thisResult) ->
		if(thisResult.website == undefined)
			locationService.getLocationDetails thisResult.place_id, @addLocationDetail
		for result in @getDisplayedResults()
			result.selected = false
		thisResult.selected = true
		updateResultsMarkers()

	@deSelectResult = (thisResult) ->
		thisResult.selected = false
		updateResultsMarkers()

	@highlightResult = (result) ->
		result.highlighted = true
		updateResultsMarkers()

	@unHighlightResult = (result) ->
		result.highlighted = false
		updateResultsMarkers()

	@toggleSelection = (result) ->
		if result.selected
			@deSelectResult result
			@triggerCloseResultsInfoWindow result
		else
			@selectResult result
			@triggerOpenResultsInfoWindow result

	@handleTextEntryClicked = (result, event) ->
		if event.target.nodeName in @clickDisablingNodes
		else
			@toggleSelection(result)

	@triggerOpenResultsInfoWindow = (result) ->
		@markerEvents = [{event: 'openresultsinfowindow',ids: ['result' + result.place_id]}];

	@triggerCloseResultsInfoWindow = (result) ->
		@markerEvents = [{event: 'closeresultsinfowindow',ids: ['result' + result.place_id]}];

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

	@getPageTitle = ->
		if isHalfwayHangout()
			return "HalfwayHangout"
		else
			return "MidwayMeetup"

	@getPageSubTitle = ->
		if isHalfwayHangout()
			return "Where do you want to hang out?"
		else
			return "Where do you want to meet up?"

	@getMeetupNomenclature = ->
		if isHalfwayHangout()
			return "hang out"
		else
			return "meet up"

	@getFavIcon = ->
		if isHalfwayHangout()
			return "img/hangout.ico"
		else
			return "img/meetup.ico"

	isHalfwayHangout = ->
		window.location.host.indexOf('halfwayhangout.com') >= 0

	@getLocationPlaceholder = ->
		if @locations.length > 0
			return "Enter another address..."
		else
			return "Enter a starting address"

	@scrollTo = (anchorTagId) ->
		$location.hash anchorTagId
		$anchorScroll()

	@initController = ->
		searchParams = $location.search()
		if searchParams.search
			@searchTerm = searchParams.search
		if searchParams.locations
			pendingLocations = searchParams.locations.split(":")
			processNextPendingLocation()

	@generatePermalink = ->
		$location.host() + "?search=" + @searchTerm + "&locations=" + @locationsToDelimitedString()

	@locationsToDelimitedString = ->
		locationString = ""
		for location in @locations
			locationString += @getNormalizedAddress(location) + ":"
		return locationString.slice(0,-1)

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

	@markerSelectedIcon = {icon: 'https://maps.gstatic.com/mapfiles/ms2/micons/yellow-dot.png'}
	@markerHighlightedIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_yellow.png'}
	@markerDefaultIcon = {icon: 'http://labs.google.com/ridefinder/images/mm_20_purple.png'}

	@mapOptions = {map: {center: new google.maps.LatLng(39, -95),zoom: 4,mapTypeId: google.maps.MapTypeId.TERRAIN}};
	@mapSearchAreaOptions = {visible: true; draggable: true, icon:"http://maps.google.com/mapfiles/arrow.png"}
	@mapLocationOptions = {draggable: false}
	@searchResultOptions = {draggable: false, clickable: true}
	@mapHiddenMarkersOptions = {visible: false}


meetupApp.controller 'ResultListController', ($scope) ->

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

	@getDirections = (fromLocation, toLocation) ->
		console.log("from " + fromLocation + " to " + toLocation)
		if fromLocation && toLocation
			link = "http://maps.google.com/maps?saddr=" + fromLocation.formatted_address + "&daddr=" +  toLocation.formatted_address
			console.log(link)
			window.open(link, "_blank");
		return true

