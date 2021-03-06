//
//  CompanyViewController.swift
//  ECaFT
//
//  Created by Logan Allen on 11/22/16.
//  Copyright © 2016 ECAFT. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase

class CompanyViewController: UIViewController, UISearchBarDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, FilterSelectionProtocol, AddRemoveDelegate {

    func unstar(company: Company) {
        print("unstar...")
        print(company.isFavorite)
        companyTableView.reloadData()
    }
    
    func star(company: Company) {
        print("star...")
        print(company.isFavorite)
        companyTableView.reloadData()
    }
    
    let screenSize : CGRect = UIScreen.main.bounds
    var searchBar : UISearchBar!
    
    // Favorites
    var favoriteUpdateStatus : (Int, String) = (0, "")
    
    // Company Table View
    var companyTableView = UITableView()
    
    // View Models
    var companyViewModel: CompanyViewModel?
    var filterViewModel: FilterViewModel?
    var listViewModel: ListViewModel?
    
    // Filtering
    // Value sent from Filters VC. Holds filter section w/ selected filter options
    var selectedFilterSects: [FilterSection]?
    
    //Database variables
    var databaseRef: DatabaseReference?
    var storageRef: StorageReference?
    var databaseHandle: DatabaseHandle?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Companies"
        view.backgroundColor = UIColor.backgroundGray
        makeSearchBar()
        makeFilterBtn()
        makeTableView()
        makeBackBtn()
        
        // Load data from firebase
        databaseRef = Database.database().reference()
        // Reference to logos folder in storage
        storageRef = Storage.storage().reference(forURL: "gs://ecaft-4a6e7.appspot.com/logos")
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toggleFilterBtnText()
        
        // Apply selected filters
        if let selectedFilterSects = selectedFilterSects {
            companyViewModel?.applyFilters(filterSections: selectedFilterSects)
            companyTableView.reloadData()
        }
        
        makeFilterBtn()
        companyTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    func loadData() {
        //Retrive posts and listen for changes
        databaseHandle = databaseRef?.child("companies").observe(.value, with: { (snapshot) in
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                let company = Company()
                company.name = item.childSnapshot(forPath: Property.name.rawValue).value as! String
                company.information = item.childSnapshot(forPath: Property.description.rawValue).value as! String
                company.location = item.childSnapshot(forPath: Property.location.rawValue).value as! String
                
                let majors = item.childSnapshot(forPath: Property.majors.rawValue).value as! String
                company.majors = majors.components(separatedBy: ", ")
                
                let positions = item.childSnapshot(forPath: Property.jobtypes.rawValue).value as! String
                company.positions = positions.components(separatedBy: ", ")
                
                company.website = item.childSnapshot(forPath: Property.website.rawValue).value as! String
                let sponsorVal = item.childSnapshot(forPath: Property.sponsor.rawValue).value as! String
                company.sponsor = (sponsorVal == "1") ? true : false
                let optcptVal = item.childSnapshot(forPath: Property.optcpt.rawValue).value as! String
                company.optcpt = (optcptVal == "1") ? true : false

                //Get image
                let companyId = item.childSnapshot(forPath: Property.id.rawValue).value as! String
                let companyImageName = companyId + ".png"
                let companyImageRef = self.storageRef?.child(companyImageName)
                companyImageRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print((error as Error).localizedDescription)
                    } else if let data = data {
                        // Data for "images/companyid.png" is returned
                        DispatchQueue.main.async { [weak self] in
                            company.image = UIImage(data: data)
                            self?.companyTableView.reloadData() //reload data here b/c this is when you know table view cell will have an image
                        }
                    }
                }
                let companyBkdName = companyId + "Background.png"
                let companyBkdRef = self.storageRef?.child(companyBkdName)
                companyBkdRef?.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print((error as Error).localizedDescription)
                    } else if let data = data {
                        // Data for "images/companyid.png" is returned
                        DispatchQueue.main.async { [weak self] in
                            company.background = UIImage(data: data)
                            self?.companyTableView.reloadData() //reload data here b/c this is when you know table view cell will have an image
                        }
                    }
                }
                self.companyViewModel?.addCompanyToAllCompanies(company)
                self.companyViewModel?.addCompanyToDisplayedCompanies(company)
            }
        })
    }

    /*** -------------------- FILTERING -------------------- ***/
    @objc func filterButtonTapped() {
        var filterViewModel: FilterViewModel
        if (self.filterViewModel != nil) {
            filterViewModel = self.filterViewModel!
        }
        else {
            self.filterViewModel = FilterViewModel()
            filterViewModel = self.filterViewModel!
        }
        let filtersVC = FiltersViewController(filterViewModel: filterViewModel)
        filtersVC.filterSelectionDelegate = self
        self.navigationController?.pushViewController(filtersVC, animated: true)
    }
    
    // Set selected filters to filters selected from Filters VC
    func setSelectedFiltersTo(filtersSent: [FilterSection]) {
        self.selectedFilterSects = filtersSent
    }
    
    // Updatedfilter bar button text
    private func toggleFilterBtnText() {
        let btnText = (filterViewModel?.isFiltersOn())! ? "Filters On" : "Filters Off"
        self.navigationItem.rightBarButtonItem?.title = btnText
    }
    
    private func makeFilterBtn() {
        let btnText = (filterViewModel?.isFiltersOn())! ? "Filters On" : "Filters Off"
        let filterButton = UIBarButtonItem(title: btnText, style: .plain, target: self, action: #selector(filterButtonTapped))
        self.navigationItem.rightBarButtonItem = filterButton
    }
    
    /*** -------------------- SEARCH BAR -------------------- ***/
    // Called whenever text is changed.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        companyViewModel?.applySearch(searchText: searchText)
        companyTableView.reloadData()
        
        // If clear button pressed
        if searchText.isEmpty {
            searchBar.resignFirstResponder()
            view.endEditing(true)
            
            companyViewModel?.clearSearchBarCompanies()
            companyViewModel?.resetDisplayedCompanies()
            companyTableView.reloadData()
        }
    }
    
    // When cancel button is clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        view.endEditing(true)
        
        companyViewModel?.clearSearchBarCompanies()
        companyViewModel?.resetDisplayedCompanies()
        companyTableView.reloadData()
    }
    
    // When done button is pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // hides the keyboard.
        view.endEditing(true)
    }
    
    // When search bar is pressed
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
    }
    
    // When keyboard return is pressed
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        view.endEditing(true)
    }
    
    private func makeSearchBar() {
        // Make UISearchBar instance
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 50)
        
        // Style & color
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchBar.tintColor = UIColor.ecaftRed
        
        // Buttons & text
        searchBar.returnKeyType = .done
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.placeholder = "company name"
        searchBar.showsBookmarkButton = false
        searchBar.showsSearchResultsButton = false
        searchBar.showsCancelButton = false
        
        view.addSubview(searchBar)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable top bounce on filterView
        scrollView.bounces = scrollView.contentOffset.y > 0
    }
    
    
    /*** -------------------- FAV BUTTON -------------------- ***/
    func didPressFavoritesBtn(button: UIButton, companyName: String) {
        
    }
    
    /*** -------------------- TABLE VIEW -------------------- ***/
    private func makeTableView() {
        //Total height of nav bar, status bar, tab bar
        let barHeights = (self.navigationController?.navigationBar.frame.size.height)!+UIApplication.shared.statusBarFrame.height + 100
        
        //edited CGRect to make margins and center it
        companyTableView = UITableView(frame: CGRect(x: 0, y: searchBar.frame.maxY, width: screenSize.width, height: screenSize.height - barHeights), style: UITableViewStyle.plain) //sets tableview to size of view below status bar and nav bar
        
        // UI
        companyTableView.backgroundColor = UIColor.backgroundGray
        companyTableView.separatorStyle = UITableViewCellSeparatorStyle.none // Removes bottom border for cells
        companyTableView.contentInset = UIEdgeInsetsMake(-27, 0, 0, 0) // Removes padding above first cell
        
        //Remove vertical scroll bar
        companyTableView.showsVerticalScrollIndicator = false;
        
        companyTableView.dataSource = self
        companyTableView.delegate = self
        
        //Regsiter custom cells and xib files
        companyTableView.register(UINib(nibName: "CompanyTableViewCell", bundle: nil), forCellReuseIdentifier: "CompanyTableViewCell")
        self.view.addSubview(self.companyTableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
    //Section: Change font color and background color for section headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let screenSize : CGRect = UIScreen.main.bounds
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        headerView.backgroundColor = UIColor.ecaftLightGray

        let label = UILabel(frame: CGRect(x: 0.05*screenSize.width, y: 0, width: screenSize.width, height: 0))
        label.center.y = 0.5*headerView.frame.height
        label.text = companyViewModel?.sectionTitles[section]
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textColor = UIColor.ecaftBlack
 
        headerView.addSubview(label)
        
        return nil
    }
 
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 120
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection
        section: Int) -> Int {
        guard let companyViewModel = companyViewModel else {
            return 0
        }
        return companyViewModel.displayedCompanies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let company = companyViewModel?.displayedCompanies[indexPath.row],
            let customCell: CompanyTableViewCell = tableView.dequeueReusableCell(withIdentifier: CompanyTableViewCell.identifier) as? CompanyTableViewCell else {
                print("CompanyViewController.swift - cellForRowAt method:  Company Table View dequeuing cell error")
                return UITableViewCell()
        }
        
        //Stops cell turning grey when click on it
        customCell.selectionStyle = .none
        
        customCell.name = company.name
        customCell.location = company.location
        customCell.delegate = self
        customCell.companyForThisCell = company
        
        //set cell borders
        customCell.contentView.layer.borderWidth = 2
        
        let myColor : UIColor = UIColor(red:0.61, green:0.15, blue:0.12, alpha:1.0)
        customCell.contentView.layer.borderColor = myColor.cgColor

        if(company.image != nil) {
            customCell.companyImage.image = company.image
        } else {
            customCell.companyImage.image = #imageLiteral(resourceName: "placeholder")
        }
        
        //added section for background image
        if(company.background != nil) {
            customCell.companyBack.image = company.background
        } else {
            customCell.companyBack.image = #imageLiteral(resourceName: "placeholder")
        }
        
        //make favorites star yellow
        if (company.isFavorite) {
            customCell.img = #imageLiteral(resourceName: "favoritesFilled")
        } else {
            customCell.img = #imageLiteral(resourceName: "favorites")
        }
        
        return customCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: false)
        let companyDetailsVC = CompanyDetailsViewController()
        companyDetailsVC.companyViewModel = companyViewModel
        companyDetailsVC.listViewModel = listViewModel
        companyDetailsVC.company = companyViewModel?.displayedCompanies[indexPath.row]
        companyDetailsVC.isFavorite = (companyViewModel?.displayedCompanies[indexPath.row].isFavorite)!
        self.show(companyDetailsVC, sender: nil)
    }


    // MARK: - Private Functions
    private func makeBackBtn() {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        self.navigationItem.backBarButtonItem = backItem
    }
}

//Makes constraint errors more readable
extension NSLayoutConstraint {
    
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)"
    }
}
