import 'package:flutter/material.dart';
import 'package:new_uber/common/model/pickup_n_drop_location_model.dart';
import 'package:new_uber/common/model/searched_address_model.dart';

class LocationProvider extends ChangeNotifier {
  List<SearchedAddressModel> searchedAddress = [];
  PickupNDropLocationModel? dropLocation;
  PickupNDropLocationModel? pickupLocation;

  nullifyDropLocation() {
    dropLocation = null;
    notifyListeners();
  }

  nullifyPickupLocation() {
    pickupLocation = null;
    notifyListeners();
  }

  updateSearchedAddress(List<SearchedAddressModel> newAddressList) {
    searchedAddress = newAddressList;
    notifyListeners();
  }

  emptySearchedAddressList() {
    searchedAddress = [];
    notifyListeners();
  }

  updateDropLocation(PickupNDropLocationModel newAddress) {
    dropLocation = newAddress;
    notifyListeners();
  }

  updatePickupLocation(PickupNDropLocationModel newAddress) {
    pickupLocation = newAddress;
    notifyListeners();
  }
}