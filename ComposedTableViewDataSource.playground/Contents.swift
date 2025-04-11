import UIKit

/// An extended version of `UITableViewDataSource` to make data sources be able to be a part of `ComposedTableViewDataSource`.
protocol ComposableTableViewDataSource: UITableViewDataSource {

    // MARK: - Properties

    /// The current number of sections.
    var sectionsCount: Int { get }
    /// The current number of section index titles.
    var sectionTitlesCount: Int { get }

    // MARK: - Methods

    /// Returns the number of rows in a section.
    /// - Parameter section: The number of the section.
    /// - Returns: The number of rows in the section.
    func numberOfRows(in section: Int) -> Int

}

// MARK: -

/// A data source that can be composed of multiple data sources.
///
/// Rows movement is not supported, updates observation is WIP.
final class ComposedTableViewDataSource: NSObject, UITableViewDataSource {

    // MARK: - Properties

    private let dataSources: [ComposableTableViewDataSource]

    // MARK: - Initialization

    /// Creates a composed data source object.
    /// - Parameter dataSources: Data source objects to be composed into a single composed data source.
    init(dataSources: ComposableTableViewDataSource...) {
        self.dataSources = dataSources
        super.init()
    }

    // MARK: Private initialization

    @available(*, unavailable)
    private override init() {
        fatalError("Initializer with parameters must be used")
    }

    // MARK: - Methods

    // MARK: ComposedTableViewDataSource protocol methods

    func numberOfSections(in tableView: UITableView) -> Int {
        // Default value if not implemented is "1".
        dataSources.reduce(0) { $0 + ($1.numberOfSections?(in: tableView) ?? 1) }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        adduce(section) { $0.tableView?(tableView, titleForHeaderInSection: $1) }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        adduce(section) { $0.tableView?(tableView, titleForFooterInSection: $1) }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        adduce(section) { $0.tableView(tableView, numberOfRowsInSection: $1) }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        adduce(indexPath) { $0.tableView(tableView, cellForRowAt: $1) }
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        adduce(indexPath) { $0.tableView?(tableView, commit: editingStyle, forRowAt: $1) }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Default if not implemented is "true".
        adduce(indexPath) { $0.tableView?(tableView, canEditRowAt: $1) ?? true }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        /*
         Movement is disabled because different data source objects can operate different object types, hence there's no
         possibility to move a corresponding object from one data source to another. At this moment, there's no way to
         figure out wether movement occurs within a single data source bounds.
         */
        false
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        /*
         There's no possibility to interrupt movement within a data source object. This method responsibility is to
         handle movement accordingly to the row's relocation.
         */
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        dataSources.reduce([String]()) { $0 + ($1.sectionIndexTitles?(for: tableView) ?? [String]()) }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        // FIXME: Force-unwrapping.
        adduceTitleIndex(index) { $0.tableView!(tableView, sectionForSectionIndexTitle: title, at: $1) }
    }

    // MARK: Private methods

    private func adduce<T>(_ section: SectionNumber, _ task: AdducedSectionTask<T>) -> T {
        let (dataSource, decomposedSection) = decompose(section: section)
        return task(dataSource, decomposedSection)
    }

    private func adduce<T>(_ indexPath: IndexPath, _ task: AdducedIndexPathTask<T>) -> T {
        let (dataSource, decomposedSection) = decompose(section: indexPath.section)
        return task(dataSource, IndexPath(row: indexPath.row, section: decomposedSection))
    }

    private func decompose(section: SectionNumber) -> (
        dataSource: ComposableTableViewDataSource, decomposedSection: SectionNumber
    ) {
        var section = section
        var dataSourceIndex = 0
        for (index, dataSource) in dataSources.enumerated() {
            let diff = section - dataSource.sectionsCount
            dataSourceIndex = index
            if diff < 0 {
                break
            } else {
                section = diff
            }
        }

        return (dataSources[dataSourceIndex], section)
    }

    private func adduceTitleIndex<T>(_ sectionTitleIndex: Int, _ task: AdducedSectionTask<T>) -> T {
        let (dataSource, decomposedSectionTitleIndex) = decompose(sectionTitleIndex: sectionTitleIndex)
        return task(dataSource, decomposedSectionTitleIndex)
    }

    private func decompose(sectionTitleIndex: Int) -> (
        dataSource: ComposableTableViewDataSource, decomposedSection: SectionNumber
    ) {
        var titleIndex = sectionTitleIndex
        var dataSourceIndex = 0
        for (index, dataSource) in dataSources.enumerated() {
            let diff = titleIndex - dataSource.sectionTitlesCount
            dataSourceIndex = index
            if diff < 0 {
                break
            } else {
                titleIndex = diff
            }
        }

        return (dataSources[dataSourceIndex], titleIndex)
    }

    // MARK: -

    private typealias SectionNumber = Int

    // MARK: -

    private typealias AdducedSectionTask<T> = (
        _ composableDataSource: ComposableTableViewDataSource, _ sectionNumber: SectionNumber
    ) -> T

    // MARK: -

    private typealias AdducedIndexPathTask<T> = (
        _ composableDataSource: ComposableTableViewDataSource, _ indexPath: IndexPath
    ) -> T

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

    // MARK: ComposableTableViewDataSource protocol properties

    let sectionsCount = 1
    let sectionTitlesCount = 0

    // MARK: Private properties

    private let books: [Book]

    // MARK: - Initialization

    init(books: Book...) {
        self.books = books
        super.init()
    }

    // MARK: - Methods

    // MARK: ComposableTableViewDataSource protocol methods

    func numberOfRows(in section: Int) -> Int {
        books.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Books"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Let's see what's next"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRows(in: section)
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

    var issue: UInt { get }
    var name: String { get }

}

// MARK: -

struct NewYorker: Magazine {

    // MARK: - Properties

    // MARK: Magazine protocol methods

    let issue: UInt
    let name = "New Yorker"

}

// MARK: -

struct NewEnglandReview: Magazine {

    // MARK: - Properties

    // MARK: Magazine protocol methods

    let issue: UInt
    let name = "New England Review"


}

// MARK: -

struct Poetry: Magazine {

    // MARK: - Properties

    // MARK: Magazine protocol methods

    let issue: UInt
    let name = "Poetry"

}

// MARK: -

final class MagazineDataSource: NSObject, ComposableTableViewDataSource {

    // MARK: - Properties

    private let magazines: [[Magazine]]

    // MARK: ComposableTableViewDataSource protocol properties

    var sectionsCount: Int { magazines.count }
    var sectionTitlesCount: Int { sectionsCount }

    // MARK: - Initialization

    init(magazines: [Magazine]...) {
        self.magazines = magazines.filter { !$0.isEmpty }
        super.init()
    }

    // MARK: - Methods

    // MARK: ComposableTableViewDataSource protocol methods

    func numberOfRows(in section: Int) -> Int {
        magazines[section].count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        magazines.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        magazines[section].first?.name
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "MagazineCell")
        cell.textLabel?.text = String(magazines[indexPath.section][indexPath.row].issue)

        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        magazines.map { String($0.first!.name.capitalized.first!) }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        index
    }

}

// MARK: Specific example

let book0 = Book(autor: "Anne Brontë", name: "The Tenant of Wildfell Hall")
let book1 = Book(autor: "Charlotte Brontë", name: "Jane Eyre")
let book2 = Book(autor: "Emily Brontë", name: "Wuthering Heights")
let booksDataSource = BookDataSource(books: book0, book1, book2)

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
let magazinesDataSource = MagazineDataSource(magazines: newYorker, newEnglandReview, poetry, empty)

let composedDataSource = ComposedTableViewDataSource(dataSources: booksDataSource, magazinesDataSource)

let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
tableView.dataSource = composedDataSource
