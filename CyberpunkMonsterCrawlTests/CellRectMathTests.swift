import XCTest
@testable import CyberpunkMonsterCrawl

/// Pure-math tests of `AtlasFamily`'s row/col -> sub-rect calculation,
/// exercised against a fixture atlas so they stay independent of any real
/// catalog asset (no image ever needs to load for these to pass or fail).
final class CellRectMathTests: XCTestCase {
    private struct FixtureAtlas: AtlasFamily {
        static let sheetName = "fixture_sheet_never_loaded"
        static let sheetSize = CGSize(width: 100, height: 80)
        static let cellSize = CGSize(width: 20, height: 20)
        static let columns = 5
        static let rows = 4
    }

    func test_cellRect_topLeftCell_startsAtOrigin() {
        let rect = FixtureAtlas.cellRect(row: 0, col: 0)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 20, height: 20))
    }

    func test_cellRect_middleCell_offsetByRowAndColumn() {
        let rect = FixtureAtlas.cellRect(row: 2, col: 3)
        XCTAssertEqual(rect, CGRect(x: 60, y: 40, width: 20, height: 20))
    }

    func test_cellRect_bottomRightCell_reachesSheetEdges() {
        let rect = FixtureAtlas.cellRect(row: FixtureAtlas.rows - 1, col: FixtureAtlas.columns - 1)
        XCTAssertEqual(rect.maxX, FixtureAtlas.sheetSize.width)
        XCTAssertEqual(rect.maxY, FixtureAtlas.sheetSize.height)
    }

    func test_cellRect_everyCellHasTheDeclaredCellSize() {
        for row in 0..<FixtureAtlas.rows {
            for col in 0..<FixtureAtlas.columns {
                let rect = FixtureAtlas.cellRect(row: row, col: col)
                XCTAssertEqual(rect.size, FixtureAtlas.cellSize, "cell (\(row), \(col)) should have the family's declared cell size")
            }
        }
    }

    func test_isInBounds_acceptsEveryValidRowAndColumn() {
        for row in 0..<FixtureAtlas.rows {
            for col in 0..<FixtureAtlas.columns {
                XCTAssertTrue(FixtureAtlas.isInBounds(row: row, col: col), "(\(row), \(col)) should be in bounds")
            }
        }
    }

    func test_isInBounds_rejectsNegativeIndices() {
        XCTAssertFalse(FixtureAtlas.isInBounds(row: -1, col: 0))
        XCTAssertFalse(FixtureAtlas.isInBounds(row: 0, col: -1))
    }

    func test_isInBounds_rejectsIndicesAtOrBeyondTheGridEdge() {
        XCTAssertFalse(FixtureAtlas.isInBounds(row: FixtureAtlas.rows, col: 0))
        XCTAssertFalse(FixtureAtlas.isInBounds(row: 0, col: FixtureAtlas.columns))
        XCTAssertFalse(FixtureAtlas.isInBounds(row: FixtureAtlas.rows + 5, col: FixtureAtlas.columns + 5))
    }
}
