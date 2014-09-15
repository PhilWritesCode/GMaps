meetupApp = angular.module 'meetupApp', ['google-maps']

meetupApp.factory 'locationService', ->
    @geocoder = new google.maps.Geocoder();

    @processLocation = (location, locations) ->
        @geocoder.geocode {address: location}, (results, status)->
            if status == google.maps.GeocoderStatus.OK
                locations.push(results[0])
            else
                alert("Failed!  Status: " + status)

    @locations = []

    @getLocations = ->
        @locations

    @addLocation = (location) ->
        if location && location not in @locations
            @processLocation location, @locations

    {@locations, @getLocations, @addLocation, @processLocation, @geocoder}


meetupApp.controller 'MeetupController',  ($scope,locationService) ->
	@products = gems
	@locations = locationService.getLocations()


meetupApp.controller 'LocationEntryController',  ($scope,locationService) ->
    @location
    @addLocation = ->
        locationService.addLocation @location
        @location = "";

meetupApp.controller 'MapController', ->
    @map = {
        center: {
            latitude: 45,
            longitude: -73
        },
        zoom: 7
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
