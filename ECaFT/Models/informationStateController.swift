//
//  informationStateController.swift
//  ECaFT
//
//  Created by Amanda Ong on 1/11/17.
//  Copyright © 2017 ECAFT. All rights reserved.
//

import Foundation

//Controls the state of the app (how data stored/transmitted)
class informationStateController {
    
    private(set) var companies = [Company]()
    private(set) var filteredCompanies = [Company]()
    var favoriteCompanies: [Company] = []
    var favoritesString: [String] = []

    //For Company Table View
    var numOfSections = 1
    var sectionTitles = ["All Companies", "Favorites", "Other Companies"]
    
    func addCompany(_ company: Company) {
        companies.append(company)
    }
    
    func removeCompany(index: Int) {
        companies.remove(at: index)
    }
    
    func clearCompanies() {
        companies = []
    }
  
    func addFilteredCompany(_ company: Company) {
        filteredCompanies.append(company)
    }
    
    func clearFilter() {
        filteredCompanies = []
    }

    func setCompanies(companies: [Company]) {
        self.companies = companies
    }
    
    func sortFavStrings() {
        favoritesString.sort {
            return $0.lowercased() < $1.lowercased()
        }
    }
    
    func sortCompaniesAlphabetically() {
        companies.sort {
            return $0.name.lowercased() < $1.name.lowercased()
        }
    }
    
    func sortFavoritesAlphabetically() {
        favoriteCompanies.sort {
            return $0.name.lowercased() < $1.name.lowercased()
        }
    }

}
