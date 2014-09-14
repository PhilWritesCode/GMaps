meetupApp = angular.module 'meetupApp', []

meetupApp.factory 'addressService', ->
    @addresses = []

    @getAddresses = ->
        @addresses

    @addAddress = (address) ->
        @addresses.push(address)
    {@addresses,@getAddresses,@addAddress}


meetupApp.controller 'MeetupController',  ($scope,addressService) ->
	@products = gems
	@addresses = addressService.getAddresses()


meetupApp.controller 'AddressEntryController',  ($scope,addressService) ->
    @address
    @addAddress = ->
        addressService.addAddress @address
        @address = "";


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