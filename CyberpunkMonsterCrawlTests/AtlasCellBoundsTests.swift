import CoreGraphics
import SpriteKit
import XCTest
@testable import CyberpunkMonsterCrawl

/// Product gate: "every cell index in every owning list resolves to an
/// in-bounds sub-rect of its sheet (fails if a row/col index is out of
/// range)."
///
/// `AtlasTextureLoaderTests` already proves the declared cell grid divides
/// evenly into the declared/measured sheet size for every family
/// (`test_everyAtlasFamily_cellGridDividesEvenlyIntoTheDeclaredSheetSize` /
/// `...MeasuredSheet`), and `CellRectMathTests` proves the row/col -> rect
/// arithmetic itself against a fixture atlas. Neither exercises the REAL
/// semantic enums a call site actually indexes by (`PlayerAtlas.Direction`,
/// `SignAtlas`'s flat 0..<12, ...). This file sweeps EVERY index each real
/// family declares through its own accessor and proves the resolved rect
/// lands inside the sheet -- which would catch, for example, an enum
/// gaining a case beyond the declared grid even though the grid arithmetic
/// alone stays self-consistent.
///
/// Paired with an explicit out-of-range probe per family: one row past the
/// last row, and one column past the last column, must be rejected BOTH by
/// the family/type-level check (`isInBounds`) and by the loader
/// (`AtlasTextureLoader.cellTexture` throwing `AtlasLoadError.indexOutOfBounds`).
final class AtlasCellBoundsTests: XCTestCase {
    private var loader: AtlasTextureLoader!

    override func setUp() {
        super.setUp()
        loader = AtlasTextureLoader()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    // MARK: - Every declared index resolves in-bounds

    func test_playerAtlas_everyDirectionAndFrame_resolvesInBounds() {
        for direction in PlayerAtlas.Direction.allCases {
            for frame in PlayerAtlas.Frame.allCases {
                assertInBounds(
                    PlayerAtlas.cellRect(direction: direction, frame: frame),
                    sheetSize: PlayerAtlas.sheetSize,
                    isInBounds: PlayerAtlas.isInBounds(row: direction.rawValue, col: frame.rawValue),
                    description: "PlayerAtlas direction=\(direction) frame=\(frame)"
                )
            }
        }
    }

    func test_weaponAtlas_everyDirectionAndWeapon_resolvesInBounds() {
        for direction in WeaponAtlas.Direction.allCases {
            for weapon in WeaponAtlas.WeaponKind.allCases {
                assertInBounds(
                    WeaponAtlas.cellRect(direction: direction, weapon: weapon),
                    sheetSize: WeaponAtlas.sheetSize,
                    isInBounds: WeaponAtlas.isInBounds(row: weapon.rawValue, col: direction.rawValue),
                    description: "WeaponAtlas direction=\(direction) weapon=\(weapon)"
                )
            }
        }
    }

    func test_raccoonWalkAtlas_everyDirectionAndFrame_resolvesInBounds() {
        for direction in RaccoonWalkAtlas.Direction.allCases {
            for frame in RaccoonWalkAtlas.Frame.allCases {
                assertInBounds(
                    RaccoonWalkAtlas.cellRect(direction: direction, frame: frame),
                    sheetSize: RaccoonWalkAtlas.sheetSize,
                    isInBounds: RaccoonWalkAtlas.isInBounds(row: direction.rawValue, col: frame.rawValue),
                    description: "RaccoonWalkAtlas direction=\(direction) frame=\(frame)"
                )
            }
        }
    }

    func test_raccoonAttackAtlas_everyDirectionAndFrame_resolvesInBounds() {
        for direction in RaccoonAttackAtlas.Direction.allCases {
            for frame in RaccoonAttackAtlas.Frame.allCases {
                assertInBounds(
                    RaccoonAttackAtlas.cellRect(direction: direction, frame: frame),
                    sheetSize: RaccoonAttackAtlas.sheetSize,
                    isInBounds: RaccoonAttackAtlas.isInBounds(row: direction.rawValue, col: frame.rawValue),
                    description: "RaccoonAttackAtlas direction=\(direction) frame=\(frame)"
                )
            }
        }
    }

    func test_bulletAtlas_everyKind_resolvesInBounds() {
        for kind in BulletAtlas.BulletKind.allCases {
            assertInBounds(
                BulletAtlas.cellRect(kind: kind),
                sheetSize: BulletAtlas.sheetSize,
                isInBounds: BulletAtlas.isInBounds(row: 0, col: kind.rawValue),
                description: "BulletAtlas kind=\(kind)"
            )
        }
    }

    func test_pulseAtlas_everyFrame_resolvesInBounds() {
        for frame in 0..<PulseAtlas.columns {
            assertInBounds(
                PulseAtlas.cellRect(frame: frame),
                sheetSize: PulseAtlas.sheetSize,
                isInBounds: PulseAtlas.isInBounds(row: 0, col: frame),
                description: "PulseAtlas frame=\(frame)"
            )
        }
    }

    func test_hitPuffAtlas_everyFrame_resolvesInBounds() {
        for frame in HitPuffAtlas.Frame.allCases {
            assertInBounds(
                HitPuffAtlas.cellRect(frame: frame),
                sheetSize: HitPuffAtlas.sheetSize,
                isInBounds: HitPuffAtlas.isInBounds(row: 0, col: frame.rawValue),
                description: "HitPuffAtlas frame=\(frame)"
            )
        }
    }

    func test_pickupAtlas_everyKind_resolvesInBounds() {
        for kind in PickupAtlas.Kind.allCases {
            assertInBounds(
                PickupAtlas.cellRect(kind: kind),
                sheetSize: PickupAtlas.sheetSize,
                isInBounds: PickupAtlas.isInBounds(row: 0, col: kind.rawValue),
                description: "PickupAtlas kind=\(kind)"
            )
        }
    }

    func test_signAtlas_everyFlatIndex_resolvesInBounds() {
        for index in 0..<(SignAtlas.columns * SignAtlas.rows) {
            let row = index / SignAtlas.columns
            let col = index % SignAtlas.columns
            assertInBounds(
                SignAtlas.cellRect(index: index),
                sheetSize: SignAtlas.sheetSize,
                isInBounds: SignAtlas.isInBounds(row: row, col: col),
                description: "SignAtlas index=\(index)"
            )
        }
    }

    // MARK: - Explicit out-of-range probe per family (type AND loader)

    func test_everyFamily_oneRowPastTheLastRow_isRejectedByTypeAndLoader() {
        assertOutOfRangeRejected(PlayerAtlas.self, row: PlayerAtlas.rows, col: 0)
        assertOutOfRangeRejected(WeaponAtlas.self, row: WeaponAtlas.rows, col: 0)
        assertOutOfRangeRejected(RaccoonWalkAtlas.self, row: RaccoonWalkAtlas.rows, col: 0)
        assertOutOfRangeRejected(RaccoonAttackAtlas.self, row: RaccoonAttackAtlas.rows, col: 0)
        assertOutOfRangeRejected(BulletAtlas.self, row: BulletAtlas.rows, col: 0)
        assertOutOfRangeRejected(PulseAtlas.self, row: PulseAtlas.rows, col: 0)
        assertOutOfRangeRejected(HitPuffAtlas.self, row: HitPuffAtlas.rows, col: 0)
        assertOutOfRangeRejected(PickupAtlas.self, row: PickupAtlas.rows, col: 0)
        assertOutOfRangeRejected(SignAtlas.self, row: SignAtlas.rows, col: 0)
    }

    func test_everyFamily_oneColumnPastTheLastColumn_isRejectedByTypeAndLoader() {
        assertOutOfRangeRejected(PlayerAtlas.self, row: 0, col: PlayerAtlas.columns)
        assertOutOfRangeRejected(WeaponAtlas.self, row: 0, col: WeaponAtlas.columns)
        assertOutOfRangeRejected(RaccoonWalkAtlas.self, row: 0, col: RaccoonWalkAtlas.columns)
        assertOutOfRangeRejected(RaccoonAttackAtlas.self, row: 0, col: RaccoonAttackAtlas.columns)
        assertOutOfRangeRejected(BulletAtlas.self, row: 0, col: BulletAtlas.columns)
        assertOutOfRangeRejected(PulseAtlas.self, row: 0, col: PulseAtlas.columns)
        assertOutOfRangeRejected(HitPuffAtlas.self, row: 0, col: HitPuffAtlas.columns)
        assertOutOfRangeRejected(PickupAtlas.self, row: 0, col: PickupAtlas.columns)
        assertOutOfRangeRejected(SignAtlas.self, row: 0, col: SignAtlas.columns)
    }

    func test_everyFamily_negativeIndices_areRejectedByTypeAndLoader() {
        assertOutOfRangeRejected(PlayerAtlas.self, row: -1, col: 0)
        assertOutOfRangeRejected(WeaponAtlas.self, row: 0, col: -1)
        assertOutOfRangeRejected(RaccoonWalkAtlas.self, row: -1, col: 0)
        assertOutOfRangeRejected(RaccoonAttackAtlas.self, row: 0, col: -1)
        assertOutOfRangeRejected(BulletAtlas.self, row: -1, col: 0)
        assertOutOfRangeRejected(PulseAtlas.self, row: 0, col: -1)
        assertOutOfRangeRejected(HitPuffAtlas.self, row: -1, col: 0)
        assertOutOfRangeRejected(PickupAtlas.self, row: 0, col: -1)
        assertOutOfRangeRejected(SignAtlas.self, row: -1, col: 0)
    }

    // MARK: - Helpers

    private func assertInBounds(
        _ rect: CGRect,
        sheetSize: CGSize,
        isInBounds: Bool,
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(isInBounds, "\(description): reported out of bounds", file: file, line: line)
        XCTAssertGreaterThanOrEqual(rect.minX, 0, description, file: file, line: line)
        XCTAssertGreaterThanOrEqual(rect.minY, 0, description, file: file, line: line)
        XCTAssertLessThanOrEqual(rect.maxX, sheetSize.width, description, file: file, line: line)
        XCTAssertLessThanOrEqual(rect.maxY, sheetSize.height, description, file: file, line: line)
    }

    private func assertOutOfRangeRejected<Family: AtlasFamily>(
        _ family: Family.Type,
        row: Int,
        col: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            Family.isInBounds(row: row, col: col),
            "\(Family.sheetName): (row \(row), col \(col)) should be out of bounds",
            file: file,
            line: line
        )
        XCTAssertThrowsError(
            try loader.cellTexture(for: family, row: row, col: col),
            "\(Family.sheetName): loader should reject (row \(row), col \(col))",
            file: file,
            line: line
        ) { error in
            guard case AtlasLoadError.indexOutOfBounds(let name, let r, let c) = error else {
                XCTFail("Expected AtlasLoadError.indexOutOfBounds, got \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(name, Family.sheetName, file: file, line: line)
            XCTAssertEqual(r, row, file: file, line: line)
            XCTAssertEqual(c, col, file: file, line: line)
        }
    }
}
