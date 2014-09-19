// Generated by CoffeeScript 1.8.0
(function() {
  var gems, meetupApp,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  meetupApp = angular.module('meetupApp', ['AngularGM', 'ngGPlaces']);

  meetupApp.factory('locationService', function() {
    this.geocoder = new google.maps.Geocoder();
    this.searcher = new google.maps.places.PlacesService(document.getElementById('results'));
    this.processLocation = (function(_this) {
      return function(newLocation, addLocation) {
        return _this.geocoder.geocode({
          address: newLocation
        }, function(results, status) {
          if (status === google.maps.GeocoderStatus.OK) {
            return addLocation(results[0]);
          } else {
            return alert("Failed!  Status: " + status);
          }
        });
      };
    })(this);
    this.performSearch = (function(_this) {
      return function(searchArea, searchTerm, displayResults) {
        return _this.searcher.textSearch({
          query: searchTerm,
          location: searchArea,
          radius: 500
        }, function(results, status) {
          if (status === google.maps.places.PlacesServiceStatus.ZERO_RESULTS) {
            alert('No results!');
            return;
          }
          return displayResults(results);
        });
      };
    })(this);
    return {
      processLocation: this.processLocation,
      performSearch: this.performSearch
    };
  });

  meetupApp.controller('MeetupController', function($scope, ngGPlacesAPI, locationService) {
    this.products = gems;
    this.locations = [];
    this.bounds = new google.maps.LatLngBounds();
    this.mapCenter;
    this.mapCenterVisible = false;
    this.searchResults;
    this.formEntry;
    this.usedEntries = [];
    this.searchTerm;
    this.searchResults;
    this.processFormEntry = function() {
      var _ref;
      if (this.formEntry && (_ref = this.formEntry, __indexOf.call(this.usedEntries, _ref) < 0)) {
        locationService.processLocation(this.formEntry, this.addLocation);
        this.usedEntries.push(this.formEntry);
      }
      return this.formEntry = "";
    };
    this.addLocation = (function(_this) {
      return function(newLocation) {
        _this.locations.push(newLocation);
        _this.updateMap();
        _this.performSearch();
        return $scope.$apply();
      };
    })(this);
    this.updateMap = (function(_this) {
      return function() {
        var location, _i, _len, _ref;
        _this.bounds = new google.maps.LatLngBounds();
        _ref = _this.locations;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          location = _ref[_i];
          _this.bounds.extend(location.geometry.location);
        }
        _this.mapCenter = _this.bounds.getCenter();
        return _this.mapCenterOptions.visible = _this.locations.length > 1;
      };
    })(this);
    this.performSearch = (function(_this) {
      return function() {
        if (!_this.searchTerm) {
          return;
        }
        return locationService.performSearch(_this.mapCenter, _this.searchTerm, _this.displayResults);
      };
    })(this);
    this.displayResults = (function(_this) {
      return function(results) {
        console.log("results: " + results);
        _this.searchResults = results;
        return $scope.$apply();
      };
    })(this);
    this.mapOptions = {
      map: {
        center: new google.maps.LatLng(39, -95),
        zoom: 4,
        mapTypeId: google.maps.MapTypeId.TERRAIN
      }
    };
    this.mapCenterOptions = {
      draggable: true,
      visible: false,
      icon: "https://maps.google.com/mapfiles/ms/icons/green-dot.png"
    };
    return this.searchResultOptions = {
      draggable: false,
      icon: "https://maps.google.com/mapfiles/ms/icons/yellow-dot.png"
    };
  });

  gems = [
    {
      name: 'Dodecahedron',
      price: 2.95,
      description: 'Here is some nonsensical description text',
      reviews: [],
      canPurchase: true,
      soldOut: true
    }, {
      name: 'Pentagonal Gem',
      price: 5.95,
      description: 'Different descriptive text',
      reviews: [],
      canPurchase: true,
      soldOut: false
    }, {
      name: 'Something new',
      price: 4.95,
      description: 'Poo dollar',
      reviews: [
        {
          stars: 5,
          body: "I love this product!",
          author: "phil@shutterfly.com"
        }
      ],
      canPurchase: true,
      soldOut: false
    }
  ];

  meetupApp.controller('PanelController', function() {
    this.tab = 1;
    this.selectTab = function(setTab) {
      return this.tab = setTab;
    };
    return this.isSelected = function(checkTab) {
      return this.tab === checkTab;
    };
  });

  meetupApp.controller('ReviewController', function() {
    this.review = {};
    return this.addReview = function(address) {
      address.reviews.push(this.review);
      return this.review = {};
    };
  });

}).call(this);
