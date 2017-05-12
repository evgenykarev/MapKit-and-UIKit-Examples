//
//  CLPlacemark.swift
//  MapPoints
//
//  Created by Evgeny Karev on 11.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import MapKit
import Contacts
import AddressBookUI

extension CLPlacemark {
    
    @available(iOS 9.0, *)
    private func postalAddressFromAddressDictionary(_ addressDictionary: Dictionary<AnyHashable, Any>) -> CNMutablePostalAddress {
        
        let address = CNMutablePostalAddress()
        
        address.street = addressDictionary[AnyHashable("Street")] as? String ?? ""
        address.state = addressDictionary[AnyHashable("State")] as? String ?? ""
        address.city = addressDictionary[AnyHashable("City")] as? String ?? ""
        address.country = addressDictionary[AnyHashable("Country")] as? String ?? ""
        address.postalCode = addressDictionary[AnyHashable("ZIP")] as? String ?? ""
        if #available(iOS 10.3, *) {
            address.subAdministrativeArea = addressDictionary[AnyHashable("SubAdministrativeArea")] as? String ?? ""
        }
        address.isoCountryCode = addressDictionary[AnyHashable("CountryCode")] as? String ?? ""
        
        return address
    }
    
    var address: String? {
        guard let addressDictionary = self.addressDictionary else {
            return nil
        }
        
        if #available(iOS 9.0, *) {
            let address = postalAddressFromAddressDictionary(addressDictionary)
            
            var addressString = ""
            
            addressString += address.country
            if #available(iOS 10.3, *) {
                addressString += ", " + address.subAdministrativeArea
            }
            addressString += ", " + address.city
            addressString += ", " + address.street
            
            return addressString
            
            // return CNPostalAddressFormatter.string(from: postalAddressFromAddressDictionary(addressDictionary), style: CNPostalAddressFormatterStyle.mailingAddress)
        } else {
            return ABCreateStringWithAddressDictionary(addressDictionary, true)
        }
    }
}
