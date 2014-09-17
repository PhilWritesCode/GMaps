meetupApp = angular.module 'meetupApp', ['AngularGM']

meetupApp.factory 'locationService', ->
    @geocoder = new google.maps.Geocoder();
    @locations = []

    @processLocation = (location, locations, refresh) =>
        @geocoder.geocode {address: location}, (results, status) ->
            if status == google.maps.GeocoderStatus.OK
                locations.push(results[0])
                refresh()
            else
                alert("Failed!  Status: " + status)

    @getLocations = =>
        @locations

    @addLocation = (location, refresh) =>
        @processLocation location, @locations, refresh

    {@getLocations, @addLocation}


meetupApp.controller 'MeetupController', ($scope,locationService) ->
	@products = gems
	@locations = locationService.getLocations()

meetupApp.controller 'LocationEntryController', ($scope,locationService) ->
    @formEntry
    @usedEntries = []
    @addLocation = ->
        if @formEntry && @formEntry not in @usedEntries
            locationService.addLocation @formEntry, @refresh
            @usedEntries.push @formEntry
        @formEntry = ""

    @refresh = =>
        $scope.$apply()

meetupApp.controller 'MapController', ($scope,locationService) ->
    @locations = locationService.getLocations()
    @bounds = new google.maps.LatLngBounds()

    @mapOptions = {
        map: {
            center: new google.maps.LatLng(39, -95),
            zoom: 4,
            mapTypeId: google.maps.MapTypeId.TERRAIN
        }
    };

    @buildIcon = (iconURL) ->
        {
            anchor : new google.maps.Point(16, 32),
            size : new google.maps.Size(32, 32),
            url : iconURL
        }

    @icons = {
        location : @buildIcon("https://maps.google.com/mapfiles/ms/icons/blue-dot.png"),
        between  : @buildIcon("https://maps.google.com/mapfiles/ms/icons/green-dot.png"),
        search   : @buildIcon("https://maps.google.com/mapfiles/ms/icons/yellow-dot.png")
    };

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
