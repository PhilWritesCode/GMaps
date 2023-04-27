(function() {
  var meetupApp,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  meetupApp = angular.module('meetupApp', ['AngularGM', 'ngGPlaces', 'ngRoute', 'ngAutocomplete']);

  meetupApp.factory('locationService', function() {
    this.geocoder = new google.maps.Geocoder();
    this.searcher = new google.maps.places.PlacesService(document.getElementById('results'));
    this.processLocation = (function(_this) {
      return function(newLocation, centerOfSearchArea, addLocation) {
        return _this.geocoder.geocode({
          address: newLocation,
          location: centerOfSearchArea
        }, function(results, status) {
          if (status === google.maps.GeocoderStatus.OK) {
            return addLocation(results[0]);
          } else if (status === google.maps.GeocoderStatus.ZERO_RESULTS) {
            return alert("Location not found!  Please try again, or add a different location.");
          } else if (status === google.maps.GeocoderStatus.OVER_QUERY_LIMIT) {
            return alert("Website is over query limit.  Please contact me at philip.t.jenkins@gmail.com");
          } else if (status === google.maps.GeocoderStatus.REQUEST_DENIED) {
            return alert("Request denied.  Please contact me at philip.t.jenkins@gmail.com");
          } else {
            return alert("Unknown Error.  Please check your internet connection and try again.");
          }
        });
      };
    })(this);
    this.performSearch = (function(_this) {
      return function(searchArea, searchTerm, displayResults, onError) {
        return _this.searcher.textSearch({
          query: searchTerm,
          location: searchArea,
          radius: 5
        }, function(results, status, pagination) {
          if (status === google.maps.places.PlacesServiceStatus.OK) {
            return displayResults(results, pagination);
          } else if (status === google.maps.places.PlacesServiceStatus.ZERO_RESULTS) {
            alert("No results found!  Please enter a different search term.");
            return onError();
          } else if (status === google.maps.places.PlacesServiceStatus.INVALID_REQUEST) {
            alert("Invalid request.  Please check search term and try again.");
            return onError();
          } else if (status === google.maps.places.PlacesServiceStatus.OVER_QUERY_LIMIT) {
            alert("Website is over query limit.  Please contact me at philip.t.jenkins@gmail.com");
            return onError();
          } else if (status === google.maps.GeocoderStatus.REQUEST_DENIED) {
            alert("Request denied.  Please contact me at philip.t.jenkins@gmail.com");
            return onError();
          } else {
            alert("Unknown Error.  Please check your internet connection and try again.");
            return onError();
          }
        });
      };
    })(this);
    this.getLocationDetails = (function(_this) {
      return function(locationReferenceId, addLocationDetails) {
        return _this.searcher.getDetails({
          placeId: locationReferenceId
        }, function(place, status) {
          if (status !== google.maps.places.PlacesServiceStatus.OK) {
            console.log("error fetching location details.");
            return;
          }
          return addLocationDetails(place);
        });
      };
    })(this);
    return {
      processLocation: this.processLocation,
      performSearch: this.performSearch,
      getLocationDetails: this.getLocationDetails
    };
  });

  meetupApp.controller('MeetupController', function($scope, $location, $anchorScroll, $routeParams, locationService) {
    var isHalfwayHangout, pendingLocations, processNextPendingLocation, updateResultsMarkers;
    this.locationMarkers = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
    this.clickDisablingNodes = ['SELECT', 'A', 'INPUT'];
    this.locations = [];
    this.bounds = new google.maps.LatLngBounds();
    this.centerOfSearchArea;
    this.locationFormEntry;
    this.searchTerm = "coffee";
    this.markerEvents;
    this.searchPages = [];
    this.searchPageIndex = 0;
    this.searchPaginationObject;
    pendingLocations = [];
    this.processLocationFormEntry = function() {
      if (this.locationFormEntry) {
        locationService.processLocation(this.locationFormEntry, this.centerOfSearchArea, this.addLocation);
      }
      return this.locationFormEntry = "";
    };
    this.addLocation = (function(_this) {
      return function(newLocation) {
        if (!_this.locationAlreadyEntered(newLocation)) {
          _this.locations.push(newLocation);
          _this.updateMapLocations();
          _this.performSearch();
          return $scope.$apply();
        }
      };
    })(this);
    processNextPendingLocation = (function(_this) {
      return function() {
        _this.locationFormEntry = pendingLocations.pop();
        return _this.processLocationFormEntry();
      };
    })(this);
    this.locationAlreadyEntered = function(locationToCheck) {
      var i, len, location, ref;
      ref = this.locations;
      for (i = 0, len = ref.length; i < len; i++) {
        location = ref[i];
        if (location.formatted_address === locationToCheck.formatted_address) {
          return true;
        }
      }
      return false;
    };
    this.removeLocation = function(locationToRemove) {
      this.locations.splice(this.locations.indexOf(locationToRemove), 1);
      this.updateMapLocations();
      return this.performSearch();
    };
    this.updateMapLocations = (function(_this) {
      return function() {
        var i, len, location, ref;
        if (_this.locations.length > 0) {
          _this.bounds = new google.maps.LatLngBounds();
          ref = _this.locations;
          for (i = 0, len = ref.length; i < len; i++) {
            location = ref[i];
            _this.bounds.extend(location.geometry.location);
          }
        }
        return _this.centerOfSearchArea = _this.bounds.getCenter();
      };
    })(this);
    this.updateMapSearchResults = (function(_this) {
      return function() {
        var i, j, len, len1, location, ref, ref1, result, results1;
        if (_this.getDisplayedResults().length > 0) {
          _this.bounds = new google.maps.LatLngBounds();
          ref = _this.locations;
          for (i = 0, len = ref.length; i < len; i++) {
            location = ref[i];
            _this.bounds.extend(location.geometry.location);
          }
          ref1 = _this.getDisplayedResults();
          results1 = [];
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            result = ref1[j];
            results1.push(_this.bounds.extend(result.geometry.location));
          }
          return results1;
        }
      };
    })(this);
    this.updateSearchArea = function(object, marker) {
      this.centerOfSearchArea = marker.getPosition();
      return this.performSearch();
    };
    this.performSearch = (function(_this) {
      return function() {
        _this.searchPages = [];
        _this.searchPageIndex = 0;
        if (!_this.searchTerm || _this.locations.length === 0) {
          updateResultsMarkers();
          return;
        }
        return locationService.performSearch(_this.centerOfSearchArea, _this.searchTerm, _this.displayResults, updateResultsMarkers);
      };
    })(this);
    this.displayResults = (function(_this) {
      return function(results, pagination) {
        _this.searchPaginationObject = pagination;
        _this.searchPages.push(results.slice(0, 10));
        if (results.length > 10) {
          _this.searchPages.push(results.slice(10));
        }
        if (_this.searchPages.length > 2) {
          _this.searchPageIndex++;
        }
        _this.updateMapSearchResults();
        $scope.$apply();
        if (pendingLocations.length > 0) {
          return processNextPendingLocation();
        }
      };
    })(this);
    updateResultsMarkers = (function(_this) {
      return function() {
        return $scope.$broadcast('gmMarkersUpdate', 'meetup.getDisplayedResults()');
      };
    })(this);
    this.getDisplayedResults = function() {
      return this.searchPages[this.searchPageIndex];
    };
    this.addLocationDetail = (function(_this) {
      return function(place) {
        var i, len, ref, result;
        ref = _this.getDisplayedResults();
        for (i = 0, len = ref.length; i < len; i++) {
          result = ref[i];
          if (result.place_id === place.place_id) {
            result.reviews = place.reviews;
            result.formatted_phone_number = place.formatted_phone_number;
            result.url = place.url;
            result.website = place.website;
            result.opening_hours = place.opening_hours;
            break;
          }
        }
        $scope.$apply();
        return updateResultsMarkers();
      };
    })(this);
    this.getLocationId = function(location) {
      return this.locationMarkers[this.locations.indexOf(location)];
    };
    this.getBaseUrl = function(fullUrl) {
      var urlParts;
      if (fullUrl) {
        urlParts = fullUrl.split('/');
        return urlParts[2];
      }
    };
    this.selectResult = function(thisResult) {
      var i, len, ref, result;
      if (thisResult.website === void 0) {
        locationService.getLocationDetails(thisResult.place_id, this.addLocationDetail);
      }
      ref = this.getDisplayedResults();
      for (i = 0, len = ref.length; i < len; i++) {
        result = ref[i];
        result.selected = false;
      }
      thisResult.selected = true;
      return updateResultsMarkers();
    };
    this.deSelectResult = function(thisResult) {
      thisResult.selected = false;
      return updateResultsMarkers();
    };
    this.highlightResult = function(result) {
      result.highlighted = true;
      return updateResultsMarkers();
    };
    this.unHighlightResult = function(result) {
      result.highlighted = false;
      return updateResultsMarkers();
    };
    this.toggleSelection = function(result) {
      if (result.selected) {
        this.deSelectResult(result);
        return this.triggerCloseResultsInfoWindow(result);
      } else {
        this.selectResult(result);
        return this.triggerOpenResultsInfoWindow(result);
      }
    };
    this.handleTextEntryClicked = function(result, event) {
      var ref;
      if (ref = event.target.nodeName, indexOf.call(this.clickDisablingNodes, ref) >= 0) {

      } else {
        return this.toggleSelection(result);
      }
    };
    this.triggerOpenResultsInfoWindow = function(result) {
      return this.markerEvents = [
        {
          event: 'openresultsinfowindow',
          ids: ['result' + result.place_id]
        }
      ];
    };
    this.triggerCloseResultsInfoWindow = function(result) {
      return this.markerEvents = [
        {
          event: 'closeresultsinfowindow',
          ids: ['result' + result.place_id]
        }
      ];
    };
    this.getNormalizedAddress = function(location) {
      var address;
      if (location) {
        address = location.formatted_address;
        if (address.indexOf(", USA") > 0) {
          return address.substr(0, address.indexOf(", USA"));
        } else if (address.indexOf(", United States") > 0) {
          return address.substr(0, address.indexOf(", United States"));
        } else {
          return address;
        }
      }
    };
    this.nextPageAvailable = function() {
      return this.searchPages.length - 1 > this.searchPageIndex || (this.searchPaginationObject && this.searchPaginationObject.hasNextPage);
    };
    this.getSearchResultPageNumbers = function() {
      if (this.getDisplayedResults()) {
        return (this.searchPageIndex * 10 + 1) + " - " + (this.searchPageIndex * 10 + this.getDisplayedResults().length);
      }
    };
    this.getPreviousPage = function() {
      if (this.searchPageIndex > 0) {
        this.searchPageIndex--;
        return this.updateMapSearchResults();
      }
    };
    this.getNextPage = function() {
      if (this.searchPages.length - 1 > this.searchPageIndex) {
        this.searchPageIndex++;
        return this.updateMapSearchResults();
      } else if (this.searchPaginationObject.hasNextPage) {
        return this.searchPaginationObject.nextPage();
      }
    };
    this.getPageTitle = function() {
      if (isHalfwayHangout()) {
        return "HalfwayHangout";
      } else {
        return "MidwayMeetup";
      }
    };
    this.getPageSubTitle = function() {
      if (isHalfwayHangout()) {
        return "Where do you want to hang out?";
      } else {
        return "Where do you want to meet up?";
      }
    };
    this.getMeetupNomenclature = function() {
      if (isHalfwayHangout()) {
        return "hang out";
      } else {
        return "meet up";
      }
    };
    this.getFavIcon = function() {
      if (isHalfwayHangout()) {
        return "img/hangout.ico";
      } else {
        return "img/meetup.ico";
      }
    };
    isHalfwayHangout = function() {
      return window.location.host.indexOf('halfwayhangout.com') >= 0;
    };
    this.getLocationPlaceholder = function() {
      if (this.locations.length > 0) {
        return "Enter another address...";
      } else {
        return "Enter a starting address";
      }
    };
    this.scrollTo = function(anchorTagId) {
      $location.hash(anchorTagId);
      return $anchorScroll();
    };
    this.initController = function() {
      var params2, searchParams;
      searchParams = $location.search();
      params2 = $routeParams;
      if (searchParams.search) {
        this.searchTerm = searchParams.search;
      }
      if (searchParams.locations) {
        pendingLocations = searchParams.locations.split(":");
        return processNextPendingLocation();
      }
    };
    this.generatePermalink = function() {
      return $location.host() + "?search=" + this.searchTerm + "&locations=" + this.locationsToDelimitedString();
    };
    this.locationsToDelimitedString = function() {
      var i, len, location, locationString, ref;
      locationString = "";
      ref = this.locations;
      for (i = 0, len = ref.length; i < len; i++) {
        location = ref[i];
        locationString += this.getNormalizedAddress(location) + ":";
      }
      return locationString.slice(0, -1);
    };
    this.getMapLocationOptions = function(result) {
      return angular.extend(this.mapLocationOptions, {
        icon: "http://maps.google.com/mapfiles/marker_grey" + this.locationMarkers[this.locations.indexOf(result)] + ".png"
      });
    };
    this.getMapSearchAreaOptions = function() {
      if (this.locations.length > 0) {
        return this.mapSearchAreaOptions;
      } else {
        return this.mapHiddenMarkersOptions;
      }
    };
    this.getMapSearchResultsOptions = function(result) {
      return angular.extend(this.searchResultOptions, result.selected ? this.markerSelectedIcon : result.highlighted ? this.markerHighlightedIcon : this.markerDefaultIcon);
    };
    this.markerSelectedIcon = {
      icon: 'https://maps.gstatic.com/mapfiles/ms2/micons/yellow-dot.png'
    };
    this.markerHighlightedIcon = {
      icon: 'http://labs.google.com/ridefinder/images/mm_20_yellow.png'
    };
    this.markerDefaultIcon = {
      icon: 'http://labs.google.com/ridefinder/images/mm_20_purple.png'
    };
    this.mapOptions = {
      map: {
        center: new google.maps.LatLng(39, -95),
        zoom: 4,
        mapTypeId: google.maps.MapTypeId.TERRAIN
      }
    };
    this.mapSearchAreaOptions = {
      visible: true,
      draggable: true,
      icon: "http://maps.google.com/mapfiles/arrow.png"
    };
    this.mapLocationOptions = {
      draggable: false
    };
    this.searchResultOptions = {
      draggable: false,
      clickable: true
    };
    return this.mapHiddenMarkersOptions = {
      visible: false
    };
  });

  meetupApp.controller('ResultListController', function($scope) {
    this.getHoursForToday = function(result) {
      var close, currentPeriod, dayIndex, open;
      dayIndex = new Date().getDay();
      if (result.opening_hours && result.opening_hours.periods) {
        currentPeriod = result.opening_hours.periods[dayIndex];
        if (currentPeriod) {
          open = this.formatHours(currentPeriod.open.hours) + ':' + this.formatMinutes(currentPeriod.open.minutes) + " " + this.getAMPM(currentPeriod.open.hours);
          close = this.formatHours(currentPeriod.close.hours) + ':' + this.formatMinutes(currentPeriod.close.minutes) + " " + this.getAMPM(currentPeriod.close.hours);
          return open + " - " + close;
        } else {
          return "Closed";
        }
      }
    };
    this.formatHours = function(rawHours) {
      if (rawHours < 13) {
        return rawHours;
      } else {
        return rawHours - 12;
      }
    };
    this.formatMinutes = function(rawMinutes) {
      if (rawMinutes > 10) {
        return rawMinutes;
      } else {
        return rawMinutes + "0";
      }
    };
    this.getAMPM = function(rawHours) {
      if (rawHours < 12) {
        return "am";
      } else {
        return "pm";
      }
    };
    return this.getDirections = function(fromLocation, toLocation) {
      var link;
      console.log("from " + fromLocation + " to " + toLocation);
      if (fromLocation && toLocation) {
        link = "http://maps.google.com/maps?saddr=" + fromLocation.formatted_address + "&daddr=" + toLocation.formatted_address;
        console.log(link);
        window.open(link, "_blank");
      }
      return true;
    };
  });

}).call(this);
