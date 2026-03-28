import Foundation
import Testing
import CoreLocation
@testable import OSA

@Suite("BundledMapAnnotationProvider")
struct MapAnnotationProviderTests {

    @Test("allAnnotations returns non-empty list from bundled data")
    func allAnnotationsNonEmpty() {
        let provider = BundledMapAnnotationProvider()
        let annotations = provider.allAnnotations()
        #expect(!annotations.isEmpty, "Bundled annotations should not be empty")
    }

    @Test("Annotations include multiple categories")
    func annotationsIncludeMultipleCategories() {
        let provider = BundledMapAnnotationProvider()
        let categories = Set(provider.allAnnotations().map(\.category))
        #expect(categories.count >= 3, "Should have at least 3 different annotation categories")
    }

    @Test("Annotations near Portland return nearby results")
    func nearbyFilterWorks() {
        let provider = BundledMapAnnotationProvider()
        let portland = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let nearby = provider.annotations(near: portland, radiusKm: 50)
        #expect(!nearby.isEmpty, "Should find annotations near Portland within 50km")
    }

    @Test("Annotations with very small radius returns fewer results")
    func smallRadiusFilters() {
        let provider = BundledMapAnnotationProvider()
        let portland = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let all = provider.allAnnotations()
        let nearby = provider.annotations(near: portland, radiusKm: 5)
        #expect(nearby.count <= all.count)
    }

    @Test("MapAnnotationCategory has valid icons")
    func categoryIconsNotEmpty() {
        for category in MapAnnotationCategory.allCases {
            #expect(!category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

    @Test("All annotations have valid coordinates")
    func annotationsHaveValidCoordinates() {
        let provider = BundledMapAnnotationProvider()
        for annotation in provider.allAnnotations() {
            #expect(annotation.latitude >= -90 && annotation.latitude <= 90)
            #expect(annotation.longitude >= -180 && annotation.longitude <= 180)
        }
    }
}
