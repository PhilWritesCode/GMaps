meetupApp = angular.module 'meetupApp', ['google-maps']

meetupApp.factory 'addressService', ->
    @geocoder = new google.maps.Geocoder();

    @processAddress = (address, addresses) ->
        @geocoder.geocode {address: address}, (results, status)->
            if status == google.maps.GeocoderStatus.OK
                addresses.push(results[0])
            else
                alert("Failed!  Status: " + status)

    @addresses = []

    @getAddresses = ->
        @addresses

    @addAddress = (address) ->
        if address && address not in @addresses
            @processAddress address, @addresses
    {@addresses,@getAddresses,@addAddress, @processAddress, @geocoder}


meetupApp.controller 'MeetupController',  ($scope,addressService) ->
	@products = gems
	@addresses = addressService.getAddresses()


meetupApp.controller 'AddressEntryController',  ($scope,addressService) ->
    @address
    @addAddress = ->
        addressService.addAddress @address
        @address = "";

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
