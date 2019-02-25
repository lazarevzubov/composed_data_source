import UIKit

/**
 `UITableViewDataSource` protocol extension to make conformants able to be a part of `ComposedTableViewDataSource`.
 */
protocol ComposableTableViewDataSource: UITableViewDataSource {
    
    // MARK: - Properties
    
    /// Current number of sections.
    var numberOfSections: Int { get }
    // Current number of section index titles.
    var numberOfSectionTitles: Int { get }
    
    // MARK: - Methods
    
    /**
     Returns number of rows of a section
     - parameter section: Number of section.
     */
    func numberOfRows(for section: Int) -> Int
    
}

// MARK: -

struct Book {
    
    // MARK: - Properties
    
    let autor: String
    let name: String
    
}

// MARK: -

final class BookDataSource: NSObject, ComposableTableViewDataSource {
    
    // MARK: - Properties
    
    private let books: [Book]
    
    // MARK: ComposableTableViewDataSource protocol properties
    
    let numberOfSections = 1
    let numberOfSectionTitles = 0
    
    // MARK: - Initialization
    
    init(books: Book...) {
        self.books = books
        super.init()
    }
    
    // MARK: - Methods
    
    // MARK: ComposableTableViewDataSource protocol methods
    
    func numberOfRows(for section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Books"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Let's see what's next"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "BookCell")
        cell.textLabel?.text = books[indexPath.row].autor
        cell.detailTextLabel?.text = books[indexPath.row].name
        
        return cell
    }
    
}

// MARK: -

protocol Magazine {
    
    // MARK: - Properties
    
    var name: String { get }
    var issue: UInt { get }
    
}

// MARK: -

struct NewYorker: Magazine {
    
    // MARK: - Properties
    
    // MARK: Magazine protocol methods
    
    var name: String { return "New Yorker" }
    let issue: UInt
    
}

// MARK: -

struct NewEnglandReview: Magazine {
    
    // MARK: - Properties
    
    // MARK: Magazine protocol methods
    
    var name: String { return "New England Review" }
    let issue: UInt
    
}

// MARK: -

struct Poetry: Magazine {
    
    // MARK: - Properties
    
    // MARK: Magazine protocol methods
    
    var name: String { return "Poetry" }
    let issue: UInt
    
}

// MARK: -

final class MagazineDataSource: NSObject, ComposableTableViewDataSource {
    
    // MARK: - Properties
    
    private let magazines: [[Magazine]]
    
    // MARK: ComposableTableViewDataSource protocol properties
    
    var numberOfSections: Int {
        return magazines.count
    }
    var numberOfSectionTitles: Int {
        return numberOfSections
    }
    
    // MARK: - Initialization
    
    init(magazines: [Magazine]...) {
        self.magazines = magazines.filter { !$0.isEmpty }
        super.init()
    }
    
    // MARK: - Methods
    
    // MARK: ComposableTableViewDataSource protocol methods
    
    func numberOfRows(for section: Int) -> Int {
        return magazines[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return magazines.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return magazines[section].first?.name
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "MagazineCell")
        cell.textLabel?.text = String(magazines[indexPath.section][indexPath.row].issue)
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return magazines.map { String($0.first!.name.capitalized.first!) }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
}

// MARK: -

/**
 Data source that can be composed of multiple original data source objects.
 Rows movements is not supported, updates observation is under implementation.
 */
final class ComposedTableViewDataSource: NSObject, UITableViewDataSource {
    
    // MARK: - Properties
    
    private let dataSources: [ComposableTableViewDataSource]
    
    // MARK: - Initialization
    
    // MARK: ComposedTableViewDataSource protocol initializers
    
    /**
     Initializes and returns composed data source object.
     - parameter dataSources: Any number of data source objects to be composed can be passed as an array or comma separated list.
     */
    init(dataSources: ComposableTableViewDataSource...) {
        self.dataSources = dataSources
        super.init()
    }
    
    private override init() {
        fatalError("ComposedTableViewDataSource: Initializer with parameters must be used.")
    }
    
    // MARK: - Methods
    
    // MARK: ComposedTableViewDataSource protocol methods
    
    // Configuring a Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        // Default value if not implemented is "1".
        return dataSources.reduce(0) { $0 + ($1.numberOfSections?(in: tableView) ?? 1) }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return adduce(section) { $0.tableView?(tableView, titleForHeaderInSection: $1) }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return adduce(section) { $0.tableView?(tableView, titleForFooterInSection: $1) }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adduce(section) { $0.tableView(tableView, numberOfRowsInSection: $1) }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return adduce(indexPath) { $0.tableView(tableView, cellForRowAt: $1) }
    }
    
    // Inserting or Deleting Table Rows
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        return adduce(indexPath) { $0.tableView?(tableView, commit: editingStyle, forRowAt: $1) }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Default if not implemented is "true".
        return adduce(indexPath) { $0.tableView?(tableView, canEditRowAt: $1) ?? true }
    }
    
    // Reordering Table Rows
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        /*
         Movement is disabled because different data source objects can operate different object types, hence there's no possibility to move a corresponding object from one data source to another. At this moment there's no way to figure out wether movement occurs within a single data source bounds.
         */
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        /*
         There's no possibility to interrupt movement within data source object. This method responsibility is to handle movement accordingly row's relocation.
         */
    }
    
    // Configuring an Index
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return dataSources.reduce([String]()) { $0 + ($1.sectionIndexTitles?(for: tableView) ?? [String]()) }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        // TODO: Think about force-unwrapping.
        return adduceTitleIndex(index) { $0.tableView!(tableView, sectionForSectionIndexTitle: title, at: $1) }
    }
    
    // MARK: Private methods
    
    private typealias SectionNumber = Int
   
    private typealias AdducedSectionTask<T> = (_ composableDataSource: ComposableTableViewDataSource, _ sectionNumber: SectionNumber) -> T
    
    private func adduce<T>(_ section: SectionNumber, _ task: AdducedSectionTask<T>) -> T {
        let (dataSource, decomposedSection) = decompose(section: section)
        return task(dataSource, decomposedSection)
    }
    
    private typealias AdducedIndexPathTask<T> = (_ composableDataSource: ComposableTableViewDataSource, _ indexPath: IndexPath) -> T
    
    private func adduce<T>(_ indexPath: IndexPath, _ task: AdducedIndexPathTask<T>) -> T {
        let (dataSource, decomposedSection) = decompose(section: indexPath.section)
        return task(dataSource, IndexPath(row: indexPath.row, section: decomposedSection))
    }
    
    private func decompose(section: SectionNumber) -> (dataSource: ComposableTableViewDataSource, decomposedSection: SectionNumber) {
        var section = section
        var dataSourceIndex = 0
        for (index, dataSource) in dataSources.enumerated() {
            let diff = section - dataSource.numberOfSections
            dataSourceIndex = index
            if diff < 0 { break } else { section = diff }
        }
        
        return (dataSources[dataSourceIndex], section)
    }
    
    private func adduceTitleIndex<T>(_ sectionTitleIndex: Int, _ task: AdducedSectionTask<T>) -> T {
        let (dataSource, decomposedSectionTitleIndex) = decompose(sectionTitleIndex: sectionTitleIndex)
        return task(dataSource, decomposedSectionTitleIndex)
    }
    
    private func decompose(sectionTitleIndex: Int) -> (dataSource: ComposableTableViewDataSource, decomposedSection: SectionNumber) {
        var titleIndex = sectionTitleIndex
        var dataSourceIndex = 0
        for (index, dataSource) in dataSources.enumerated() {
            let diff = titleIndex - dataSource.numberOfSectionTitles
            dataSourceIndex = index
            if diff < 0 { break } else { titleIndex = diff }
        }
        
        return (dataSources[dataSourceIndex], titleIndex)
    }
    
}

let book0 = Book(autor: "Anne Brontë", name: "The Tenant of Wildfell Hall")
let book1 = Book(autor: "Charlotte Brontë", name: "Jane Eyre")
let book2 = Book(autor: "Emily Brontë", name: "Wuthering Heights")
let bookDataSource = BookDataSource(books: book0, book1, book2)

let magazine0 = NewYorker(issue: 1)
let magazine1 = NewYorker(issue: 2)
let newYorker: [Magazine] = [magazine0, magazine1]
let magazine2 = NewEnglandReview(issue: 1)
let magazine3 = NewEnglandReview(issue: 2)
let magazine4 = NewEnglandReview(issue: 3)
let newEnglandReview: [Magazine] = [magazine2, magazine3, magazine4]
let magazine5 = Poetry(issue: 1)
let poetry: [Magazine] = [magazine5]
let empty = [Magazine]()
let magazineDataSource = MagazineDataSource(magazines: newYorker, newEnglandReview, poetry, empty)

let composedDataSource = ComposedTableViewDataSource(dataSources: bookDataSource, magazineDataSource)

let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
tableView.dataSource = composedDataSource
