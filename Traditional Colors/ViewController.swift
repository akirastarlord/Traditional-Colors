//
//  ViewController.swift
//  WebParser
//
//  Created by yy的mac on 2019/11/21.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import UIKit


extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearch(searchText)
        }
    }

}

/* Uncomment this extension to do comprehensive parsing
 of https://irocore.com/ and write to local JSON file */
/**
extension MainViewController: ReaderManagerDelegate {
    func didFinishToplevelReading(_ p: Parser) {
        p.readComprehensive()
    }
    
    func didFinishComprehensiveReading(_ p: Parser) {
        print("Finished comprehensive reading")
        p.writeToJsonFile()
    }
}
*/

class MainViewController: UITableViewController, ParserDelegate {
    
    var colors = [Color]()
    
    var filteredColors = [Color]()
    
    /* SearchController that uses the current view of showing result */
    let searchController = UISearchController(searchResultsController: nil)
    
    /* A computed property that shows whether search bar is empty, default = true */
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    var isSearching: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let uf = UserFamily()
        //uf.userTest()
        uf.firebaseTest()
        
        configureSearchController()
        
        let parser = Parser(url: "https://irocore.com/")
        parser.delegate = self
        
        //parser.parserManager = self
        
        //p.doKanna()
        parser.doSwiftSoup()
        
        
        /*
        colors.append(Color(name: "Magic", colorCode: "#000000",
                            hiragana: "マジック", romanji: "majikku"))
        
        colors.append(Color(name: "Magic", colorCode: "#ff0000"))
        //print(colors[0])
        //print(UIColor(hex: colors[0].colorCode) ?? "invalid test color")
         
        colors[0].link = "https://irocore.com/aiirohatoba/"
        let r = Parser(url: "s")
        r.readDetailPage(colors[0])
         */
        
    }
    
    // MARK: - search controller method
    private func configureSearchController() {
        /* like setting "delegate" of UISearchResultingUpdating protocol
         to this VC, informing any change in UISearchBar */
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "search for colors"
        
        /* By conventinon SearchController needs to be in NavigationItem
         from iOS 11 */
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        /* let the parent NavigationController be the presentation context
         in order to preserve the NavigationController functionalities
         like back button when presenting results */
        self.definesPresentationContext = true
        /* hides navigation bar during searching -> searchbar becomes the navigation bar */
        //searchController.hidesNavigationBarDuringPresentation = true
    }
    
    // MARK: - table view methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredColors.count
        }
        return colors.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: "Color")
        let color: Color
        if isSearching {
            color = filteredColors[indexPath.row]
        }
        else {
            color = colors[indexPath.row]
        }
        if let c = c {
            if let colorView = c.viewWithTag(1) {
                colorView.backgroundColor = UIColor(hex: color.colorCode)
            }
            if let nameLabel = c.viewWithTag(2) as? UILabel {
                nameLabel.text = color.name
            }
            if let pronounciationLabel = c.viewWithTag(3) as? UILabel {
                pronounciationLabel.text = color.romanji
            }
        }
        return c ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let color: Color
        if isSearching { color = filteredColors[indexPath.row] }
        else { color = colors[indexPath.row] }
        performSegue(withIdentifier: "ShowStory", sender: color)
    }
    
    // MARK: - end of table view methods
    
    
    // MARK: - Parser Delegate method
    func didFinishCollectingColors(_ colorList: [Color]) {
        colors = colorList
        filteredColors = colors
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Segue method
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowStory" {
            if let detailVC = segue.destination as? DetailViewController {
                if let c = sender as? Color {
                    detailVC.color = c
                }
            }
        }
    }
    
    // MARK: - Refresh Control method
    /*
    func configureRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
    }
     */
    
    
    // MARK: - Process search text
    func filterContentForSearch(_ searchText: String) {
        filteredColors = colors.filter { (c: Color) -> Bool in
            return c.name.contains(searchText) ||
                c.romanji!.lowercased().contains(searchText.lowercased())
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }


}

