//
//  FirebaseIntegrationTests.swift
//
//  Created by Vishal Gupta on 07/11/25.
//

import Testing
import Foundation
import RudderStackAnalytics
@testable import FirebaseSampleIntegration

struct FirebaseIntegrationTests {
    
    // MARK: - Test Setup Helpers
    
    private func createFirebaseIntegration(
        mockAnalyticsAdapter: MockFirebaseAnalyticsAdapter = MockFirebaseAnalyticsAdapter(),
        mockAppAdapter: MockFirebaseAppAdapter = MockFirebaseAppAdapter()
    ) -> FirebaseIntegration {
        return FirebaseIntegration(
            analyticsAdapter: mockAnalyticsAdapter,
            appAdapter: mockAppAdapter
        )
    }
    
    private func createIdentifyEvent(userId: String? = nil, traits: [String: Any]? = nil) -> IdentifyEvent {
        var userIdentity = UserIdentity()
        if let userId = userId {
            userIdentity.userId = userId
        }
        if let traits = traits {
            userIdentity.traits = traits
        }
        var event = IdentifyEvent()
        event.userId = userId
        event.context = event.context ?? [:] + (["traits": traits ?? [:]].mapValues { AnyCodable($0) })

        return event
    }
    
    private func createTrackEvent(name: String, properties: [String: Any]? = nil) -> TrackEvent {
        return TrackEvent(event: name, properties: properties)
    }
    
    private func createScreenEvent(name: String, properties: [String: Any]? = nil) -> ScreenEvent {
        return ScreenEvent(screenName: name, properties: properties)
    }
    
    // MARK: - Initialization Tests
    
    @Test("Given FirebaseIntegration, when initialized with default constructor, then creates proper adapters")
    func testFirebaseIntegrationDefaultInitialization() {
        // When
        let firebaseIntegration = FirebaseIntegration()
        
        // Then
        #expect(firebaseIntegration.key == "Firebase")
        #expect(firebaseIntegration.pluginType == .terminal)
        #expect(firebaseIntegration.analytics == nil) // Not set until added to Analytics
    }
    
    @Test("Given FirebaseIntegration, when initialized with custom adapters, then uses provided adapters")
    func testFirebaseIntegrationCustomInitialization() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let mockAppAdapter = MockFirebaseAppAdapter()
        
        // When
        let firebaseIntegration = createFirebaseIntegration(
            mockAnalyticsAdapter: mockAnalyticsAdapter,
            mockAppAdapter: mockAppAdapter
        )
        
        // Then
        #expect(firebaseIntegration.key == "Firebase")
        #expect(firebaseIntegration.pluginType == .terminal)
    }
    
    // MARK: - Create/Setup Tests
    
    @Test("Given unconfigured Firebase app, when create is called, then Firebase is configured")
    func testCreateConfiguresFirebaseWhenNotConfigured() {
        // Given
        let mockAppAdapter = MockFirebaseAppAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAppAdapter: mockAppAdapter)
        #expect(mockAppAdapter.isConfigured == false)
        
        // When
        try? firebaseIntegration.create(destinationConfig: [:])
        
        // Then
        #expect(mockAppAdapter.isConfigured == true)
    }
    
    @Test("Given already configured Firebase app, when create is called, then Firebase configuration is skipped")
    func testCreateSkipsConfigurationWhenAlreadyConfigured() {
        // Given
        let mockAppAdapter = MockFirebaseAppAdapter()
        mockAppAdapter.configure() // Pre-configure Firebase
        let firebaseIntegration = createFirebaseIntegration(mockAppAdapter: mockAppAdapter)
        #expect(mockAppAdapter.isConfigured == true)
        
        // When
        try? firebaseIntegration.create(destinationConfig: [:])
        
        // Then
        #expect(mockAppAdapter.isConfigured == true) // Still configured
    }
    
    @Test("Given configured Firebase integration, when getDestinationInstance is called, then returns analytics instance")
    func testGetDestinationInstanceReturnsAnalyticsWhenConfigured() {
        // Given
        let mockAppAdapter = MockFirebaseAppAdapter()
        mockAppAdapter.configure()
        let firebaseIntegration = createFirebaseIntegration(mockAppAdapter: mockAppAdapter)
        
        // When
        let instance = firebaseIntegration.getDestinationInstance()
        
        // Then
        #expect(instance != nil)
    }
    
    @Test("Given unconfigured Firebase integration, when getDestinationInstance is called, then returns nil")
    func testGetDestinationInstanceReturnsNilWhenNotConfigured() {
        // Given
        let mockAppAdapter = MockFirebaseAppAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAppAdapter: mockAppAdapter)
        #expect(mockAppAdapter.isConfigured == false)
        
        // When
        let instance = firebaseIntegration.getDestinationInstance()
        
        // Then
        #expect(instance == nil)
    }
    
    // MARK: - Identify Event Tests
    
    @Test("Given identify event with userId, when identify is called, then Firebase userId is set")
    func testIdentifyWithUserId() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let mockAppAdapter = MockFirebaseAppAdapter()
        mockAppAdapter.configure()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter, mockAppAdapter: mockAppAdapter)
        let identifyEvent = createIdentifyEvent(userId: "user123")
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        print("DEBUG: setUserIDCalls count = \(mockAnalyticsAdapter.setUserIDCalls.count)")
        #expect(mockAnalyticsAdapter.setUserIDCalls.count == 1)
        if mockAnalyticsAdapter.setUserIDCalls.count > 0 {
            #expect(mockAnalyticsAdapter.setUserIDCalls[0] == "user123")
        }
    }
    
    @Test("Given identify event with empty userId, when identify is called, then Firebase userId is not set")
    func testIdentifyWithEmptyUserId() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let identifyEvent = createIdentifyEvent(userId: "")
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.setUserIDCalls.isEmpty)
        #expect(mockAnalyticsAdapter.setUserIDWithNilCalled == false)
    }
    
    @Test("Given identify event with nil userId, when identify is called, then Firebase userId is not set")
    func testIdentifyWithNilUserId() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let identifyEvent = createIdentifyEvent(userId: nil)
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.setUserIDCalls.isEmpty)
        #expect(mockAnalyticsAdapter.setUserIDWithNilCalled == false)
    }
    
    @Test("Given identify event with user traits, when identify is called, then Firebase user properties are set")
    func testIdentifyWithUserTraits() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let traits = [
            "email": "test@example.com",
            "name": "Test User",
            "age": 25, // this is a reserved keyword, so won't be added
            "isVip": true
        ] as [String: Any]
        let identifyEvent = createIdentifyEvent(userId: "user123", traits: traits)
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.setUserIDCalls.count == 1)
        #expect(mockAnalyticsAdapter.setUserIDCalls[0] == "user123")
        #expect(mockAnalyticsAdapter.setUserPropertyCalls.count == 3)
        
        // Verify specific user properties
        let propertyNames = mockAnalyticsAdapter.setUserPropertyCalls.map { $0.name }
        let propertyValues = mockAnalyticsAdapter.setUserPropertyCalls.map { $0.value }
        
        #expect(propertyNames.contains("email"))
        #expect(propertyNames.contains("name"))
        
        #expect(propertyNames.contains("isvip"))
        
        #expect(propertyValues.contains("test@example.com"))
        #expect(propertyValues.contains("Test User"))
        
        #expect(propertyValues.contains("true"))
    }
    
    @Test("Given identify event with reserved keyword traits, when identify is called, then reserved keywords are filtered out")
    func testIdentifyWithReservedKeywordTraits() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let traits = [
            "email": "test@example.com",
            "userId": "should_be_filtered", // Reserved keyword
            "first_name": "Test",
            "age": "25"
        ] as [String: Any]
        let identifyEvent = createIdentifyEvent(userId: "user123", traits: traits)
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        let propertyNames = mockAnalyticsAdapter.setUserPropertyCalls.map { $0.name }
        #expect(!propertyNames.contains("userId")) // Should be filtered out
        #expect(propertyNames.contains("email"))
        #expect(propertyNames.contains("first_name"))
        #expect(!propertyNames.contains("age"))
    }
    
    @Test("Given identify event with traits containing special characters, when identify is called, then keys are trimmed properly")
    func testIdentifyWithTraitsSpecialCharacters() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let traits = [
            "user-name": "Test User",
            "user_email": "test@example.com",
            "user.age": 25,
            "User Profession": "Dev",
            " User Address  ": "123 Main St"
        ] as [String: Any]
        let identifyEvent = createIdentifyEvent(userId: "user123", traits: traits)
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        let propertyNames = mockAnalyticsAdapter.setUserPropertyCalls.map { $0.name }
        #expect(propertyNames.contains("user-name"))
        #expect(propertyNames.contains("user_email"))
        #expect(propertyNames.contains("user.age"))
        #expect(propertyNames.contains("user_profession"))
        #expect(propertyNames.contains("user_address"))
    }
    
    // MARK: - Track Event Tests
    
    @Test("Given empty event name, when track is called, then event is dropped")
    func testTrackWithEmptyEventName() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let trackEvent = createTrackEvent(name: "")
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.isEmpty)
    }
    
    @Test("Given Application Opened event, when track is called, then Firebase app_open event is logged")
    func testTrackApplicationOpenedEvent() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties: [String: Any] = ["source": "app_launch"]
        let trackEvent = createTrackEvent(name: "Application Opened", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "app_open")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["source"] as? String == "app_launch")
    }
    
    @Test("Given custom event, when track is called, then custom event is logged with formatted name")
    func testTrackCustomEvent() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties: [String: Any] = ["key1": "value1", "key2": 123]
        let trackEvent = createTrackEvent(name: "Custom Event Name", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "custom_event_name")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["key1"] as? String == "value1")
        #expect(parameters?["key2"] as? Double == 123.0)
    }
    
    @Test("Given ecommerce event Product Added, when track is called, then Firebase add_to_cart event is logged")
    func testTrackEcommerceProductAdded() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123",
            "name": "Test Product",
            "price": 99.99,
            "currency": "USD"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Added", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "add_to_cart")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["currency"] as? String == "USD")
        #expect(parameters?["value"] == nil) // value is a reserved keyword
    }
    
    @Test("Given ecommerce event Order Completed, when track is called, then Firebase purchase event is logged with transaction details")
    func testTrackEcommerceOrderCompleted() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "order_id": "order123",
            "revenue": 199.99,
            "tax": 20.0,
            "shipping": 10.0,
            "currency": "USD",
            "products": [
                [
                    "product_id": "prod1",
                    "name": "Product 1",
                    "price": 99.99
                ],
                [
                    "product_id": "prod2",
                    "name": "Product 2",
                    "price": 100.0
                ]
            ]
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Order Completed", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "purchase")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["transaction_id"] as? String == "order123")
        #expect(parameters?["value"] as? Double == 199.99)
        #expect(parameters?["tax"] as? Double == 20.0)
        #expect(parameters?["shipping"] as? Double == 10.0)
        #expect(parameters?["currency"] as? String == "USD")
        #expect(parameters?["order_id"] as? String == "order123") // Backward compatibility
    }
    
    @Test("Given ecommerce event Product Shared, when track is called, then Firebase share event is logged with content type")
    func testTrackEcommerceProductShared() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123",
            "share_via": "facebook"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Shared", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "share")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["item_id"] as? String == "prod123")
        #expect(parameters?["content_type"] as? String == "product")
        #expect(parameters?["method"] as? String == "facebook")
    }
    
    @Test("Given ecommerce event Cart Shared, when track is called, then Firebase share event is logged with cart details")
    func testTrackEcommerceCartShared() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "cart_id": "cart123",
            "share_via": "email"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Cart Shared", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "share")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["item_id"] as? String == "cart123")
        #expect(parameters?["content_type"] as? String == "cart")
        #expect(parameters?["method"] as? String == "email")
    }
    
    @Test("Given ecommerce event with promotion details, when track is called, then Firebase promotion event is logged")
    func testTrackEcommercePromotionViewed() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "name": "Summer Sale",
            "promotion_id": "promo123",
            "creative": "banner_ad"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Promotion Viewed", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "view_promotion")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["promotion_name"] as? String == "Summer Sale")
        #expect(parameters?["promotion_id"] as? String == "promo123")
        #expect(parameters?["creative_name"] as? String == "banner_ad")
    }
    
    @Test("Given ecommerce event Product Clicked, when track is called, then Firebase select_content event is logged")
    func testTrackEcommerceProductClicked() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Clicked", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "select_content")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["item_id"] as? String == "prod123")
        #expect(parameters?["content_type"] as? String == "product")
    }
    
    @Test("Given ecommerce event with default currency, when track is called, then USD currency is used")
    func testTrackEcommerceEventWithDefaultCurrency() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123",
            "price": 50.0
            // No currency specified
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Added", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["currency"] as? String == "USD")
    }
    
    @Test("Given track event with long string properties, when track is called, then strings are truncated to 100 characters")
    func testTrackEventWithLongStringProperties() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let longString = String(repeating: "a", count: 150) // 150 characters
        let properties = [
            "long_description": longString,
            "short_name": "test"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Custom Event", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        let truncatedDescription = parameters?["long_description"] as? String
        #expect(truncatedDescription?.count == 100)
        #expect(parameters?["short_name"] as? String == "test")
    }
    
    // MARK: - Screen Event Tests
    
    @Test("Given screen event with valid name, when screen is called, then Firebase screen_view event is logged")
    func testScreenEventWithValidName() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties: [String: Any] = ["category": "navigation", "path": "/home"]
        let screenEvent = createScreenEvent(name: "Home Screen", properties: properties)
        
        // When
        firebaseIntegration.screen(payload: screenEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "screen_view")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["screen_name"] as? String == "Home Screen")
        #expect(parameters?["category"] == nil) // category is reserved keyword
        #expect(parameters?["path"] as? String == "/home")
    }
    
    @Test("Given screen event with empty name, when screen is called, then event is dropped")
    func testScreenEventWithEmptyName() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let screenEvent = createScreenEvent(name: "")
        
        // When
        firebaseIntegration.screen(payload: screenEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.isEmpty)
    }
    
    @Test("Given screen event with properties, when screen is called, then all properties are included")
    func testScreenEventWithProperties() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "category": "ecommerce",
            "product_count": 5,
            "is_logged_in": true,
            "loading_time": 2.5
        ] as [String: Any]
        let screenEvent = createScreenEvent(name: "Product List", properties: properties)
        
        // When
        firebaseIntegration.screen(payload: screenEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["screen_name"] as? String == "Product List")
        #expect(parameters?["category"] == nil)
        #expect(parameters?["product_count"] as? Double == 5)
        #expect(parameters?["is_logged_in"] as? Double == 1.0) // boolean is treated as a number value
        #expect(parameters?["loading_time"] as? Double == 2.5)
    }
    
    // MARK: - Reset Event Tests
    
    @Test("Given Firebase integration, when reset is called, then Firebase userId is cleared")
    func testReset() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        
        // When
        firebaseIntegration.reset()
        
        // Then
        #expect(mockAnalyticsAdapter.setUserIDWithNilCalled == true)
    }
    
    // MARK: - Product Handling Tests
    
    @Test("Given ecommerce event with products array, when track is called, then products are properly mapped")
    func testTrackEventWithProductsArray() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "products": [
                [
                    "product_id": "prod1",
                    "name": "Product 1",
                    "price": 25.0,
                    "quantity": 2,
                    "category": "electronics"
                ],
                [
                    "product_id": "prod2",
                    "name": "Product 2",
                    "price": 50.0,
                    "quantity": 1,
                    "category": "books"
                ]
            ]
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Order Completed", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["currency"] as? String == "USD") // Default currency
        // Items array should be populated with mapped products
        let items = parameters?["items"] as? [[String: Any]]
        #expect(items?.count == 2)
    }
    
    @Test("Given ecommerce event with root-level product properties, when track is called, then single product is mapped")
    func testTrackEventWithRootLevelProduct() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123",
            "name": "Single Product",
            "price": 75.0,
            "quantity": 3,
            "category": "clothing"
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Added", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["currency"] as? String == "USD")
        // Single product should be mapped
        let items = parameters?["items"] as? [[String: Any]]
        #expect(items?.count == 1)
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("Given track event with nil properties, when track is called, then handles gracefully")
    func testTrackEventWithNilProperties() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let trackEvent = createTrackEvent(name: "Simple Event")
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "simple_event")
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?.isEmpty == true)
    }
    
    @Test("Given identify event with nil traits, when identify is called, then handles gracefully")
    func testIdentifyEventWithNilTraits() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let identifyEvent = createIdentifyEvent(userId: "user123")
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.setUserIDCalls.count == 1)
        #expect(mockAnalyticsAdapter.setUserIDCalls[0] == "user123")
        #expect(mockAnalyticsAdapter.setUserPropertyCalls.isEmpty)
    }
    
    @Test("Given ecommerce event with invalid product data types, when track is called, then handles gracefully")
    func testTrackEcommerceEventWithInvalidProductData() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "product_id": "prod123",
            "price": "invalid_price", // String instead of number
            "quantity": "two", // String instead of number
            "name": 12345 // Number instead of string
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Product Added", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        // Should not crash and should handle the invalid data gracefully
    }
    
    @Test("Given track event with mixed data types, when track is called, then converts values appropriately")
    func testTrackEventWithMixedDataTypes() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        let properties = [
            "string_value": "text",
            "int_value": 42,
            "double_value": 3.14,
            "bool_value": true,
            "nil_value": NSNull()
        ] as [String: Any]
        let trackEvent = createTrackEvent(name: "Mixed Types Event", properties: properties)
        
        // When
        firebaseIntegration.track(payload: trackEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 1)
        let parameters = mockAnalyticsAdapter.logEventCalls[0].parameters
        #expect(parameters?["string_value"] as? String == "text")
        #expect(parameters?["int_value"] as? Double == 42) // int value is converted to double
        #expect(parameters?["double_value"] as? Double == 3.14)
        #expect(parameters?["bool_value"] as? Double == 1) // boolean value is converted to double
        // nil_value should be filtered out
    }
    
    // MARK: - Integration Tests
    
    @Test("Given complete ecommerce flow, when multiple events are tracked, then all events are properly logged")
    func testCompleteEcommerceFlow() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        
        // Product Viewed
        let productViewedEvent = createTrackEvent(
            name: "Product Viewed",
            properties: [
                "product_id": "prod123",
                "name": "Test Product",
                "price": 99.99,
                "category": "electronics"
            ]
        )
        
        // Product Added to Cart
        let productAddedEvent = createTrackEvent(
            name: "Product Added",
            properties: [
                "product_id": "prod123",
                "name": "Test Product",
                "price": 99.99,
                "quantity": 1
            ]
        )
        
        // Order Completed
        let orderCompletedEvent = createTrackEvent(
            name: "Order Completed",
            properties: [
                "order_id": "order123",
                "revenue": 99.99,
                "products": [
                    [
                        "product_id": "prod123",
                        "name": "Test Product",
                        "price": 99.99,
                        "quantity": 1
                    ]
                ]
            ]
        )
        
        // When
        firebaseIntegration.track(payload: productViewedEvent)
        firebaseIntegration.track(payload: productAddedEvent)
        firebaseIntegration.track(payload: orderCompletedEvent)
        
        // Then
        #expect(mockAnalyticsAdapter.logEventCalls.count == 3)
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "view_item")
        #expect(mockAnalyticsAdapter.logEventCalls[1].name == "add_to_cart")
        #expect(mockAnalyticsAdapter.logEventCalls[2].name == "purchase")
    }
    
    @Test("Given user identification and tracking flow, when events are processed, then user context is maintained")
    func testUserIdentificationAndTrackingFlow() {
        // Given
        let mockAnalyticsAdapter = MockFirebaseAnalyticsAdapter()
        let firebaseIntegration = createFirebaseIntegration(mockAnalyticsAdapter: mockAnalyticsAdapter)
        
        // Identify user
        let identifyEvent = createIdentifyEvent(
            userId: "user123",
            traits: [
                "email": "test@example.com",
                "name": "Test User",
                "plan": "premium"
            ]
        )
        
        // Track custom event
        let customEvent = createTrackEvent(
            name: "Feature Used",
            properties: [
                "feature": "advanced_analytics",
                "usage_count": 5
            ]
        )
        
        // Screen view
        let screenEvent = createScreenEvent(
            name: "Dashboard",
            properties: [
                "section": "analytics",
                "widgets_count": 3
            ]
        )
        
        // When
        firebaseIntegration.identify(payload: identifyEvent)
        firebaseIntegration.track(payload: customEvent)
        firebaseIntegration.screen(payload: screenEvent)
        
        // Then
        // User identification
        #expect(mockAnalyticsAdapter.setUserIDCalls.count == 1)
        #expect(mockAnalyticsAdapter.setUserIDCalls[0] == "user123")
        #expect(mockAnalyticsAdapter.setUserPropertyCalls.count == 3)
        
        // Event tracking
        #expect(mockAnalyticsAdapter.logEventCalls.count == 2) // Custom event + Screen view
        #expect(mockAnalyticsAdapter.logEventCalls[0].name == "feature_used")
        #expect(mockAnalyticsAdapter.logEventCalls[1].name == "screen_view")
    }
}


extension Dictionary where Key == String {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        return lhs.merging(rhs) { (_, new) in new }
    }
}
