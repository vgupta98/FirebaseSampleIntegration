// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import FirebaseCore
import FirebaseAnalytics
import RudderStackAnalytics

/**
 * Firebase Integration for RudderStack Swift SDK
 * 
 * This class provides Firebase Analytics integration for the RudderStack Swift SDK.
 * It converts RudderStack events to Firebase Analytics events and handles user identification.
 */
class FirebaseIntegration: IntegrationPlugin, StandardIntegration {
    
    // MARK: - Required Properties
    
    /// Plugin type is always terminal for integration plugins
    var pluginType: PluginType = .terminal
    
    /// Reference to the analytics instance
    var analytics: RudderStackAnalytics.Analytics?
    
    /// Integration key identifier
    var key: String = "Firebase"
    
    // MARK: - Private Properties
    
    // No private state needed - integration framework handles configuration tracking
    
    // MARK: - Required Methods
    
    /**
     * Creates and initializes the Firebase integration
     * Equivalent to Objective-C: initWithConfig:withAnalytics:withRudderConfig:
     */
    func create(destinationConfig: [String: Any]) throws {
        // Ensure Firebase initialization happens on the main queue (like Objective-C version)
        DispatchQueue.main.sync {
            // Check if Firebase is already configured to avoid duplicate initialization
            if FirebaseApp.app() == nil {
                // Configure Firebase - equivalent to [FIRApp configure] in Objective-C
                FirebaseApp.configure()
                LoggerAnalytics.debug("Firebase is initialized")
            } else {
                // Firebase already initialized - skip configuration
                LoggerAnalytics.debug("Firebase core already initialized - skipping Firebase configuration")
            }
        }
    }
    
    /**
     * Returns the Firebase Analytics instance
     * Required by IntegrationPlugin protocol
     */
    func getDestinationInstance() -> Any? {
        // Return Firebase Analytics class if Firebase is configured
        return FirebaseApp.app() != nil ? FirebaseAnalytics.Analytics.self : nil
    }
    
    // MARK: - Optional Methods (implement only if needed)
    
    /**
     * Updates destination configuration dynamically
     * Swift-specific feature for dynamic config updates
     */
    func update(destinationConfig: [String: Any]) throws {
        // Firebase doesn't require configuration updates after initialization
        // The integration framework handles destination config changes
        LoggerAnalytics.debug("Firebase configuration update requested - no action needed")
    }
    
    /**
     * Resets user state - equivalent to Objective-C reset method
     */
    func reset() {
        // Clear Firebase user ID - equivalent to [FIRAnalytics setUserID:nil]
        FirebaseAnalytics.Analytics.setUserID(nil)
        LoggerAnalytics.debug("Reset: Firebase Analytics setUserID:nil")
    }
    
    /**
     * Flushes pending events - equivalent to Objective-C flush method
     */
    func flush() {
        // Firebase doesn't support flush functionality - no-op implementation
        LoggerAnalytics.debug("Firebase flush requested - no action needed (Firebase doesn't support flush)")
    }
    
    // MARK: - Event Methods (extract from Objective-C dump logic)
    
    /**
     * Handles identify events
     * Extracted from Objective-C dump method's identify handling
     */
    func identify(payload: IdentifyEvent) {
        // Set Firebase user ID if present - equivalent to [FIRAnalytics setUserID:userId]
        if let userId = payload.userId, !FirebaseUtils.isEmpty(userId) {
            LoggerAnalytics.debug("Setting userId to firebase")
            FirebaseAnalytics.Analytics.setUserID(userId)
        }
        
        // Set user properties from traits - equivalent to [FIRAnalytics setUserPropertyString:forName:]
        if let traits = payload.traits?.dictionary {
            for (key, value) in traits {
                // Skip userId key to avoid duplication
                guard key != "userId" else { continue }
                
                // Trim and format the key - equivalent to [RudderUtils getTrimKey:]
                let firebaseKey = FirebaseUtils.getTrimKey(key)
                
                // Filter out reserved keywords - equivalent to IDENTIFY_RESERVED_KEYWORDS check
                guard !FirebaseUtils.identifyReservedKeywords.contains(firebaseKey) else { continue }
                
                // Set user property with string conversion
                let stringValue = "\(value)"
                LoggerAnalytics.debug("Setting userProperty to Firebase: \(firebaseKey)")
                FirebaseAnalytics.Analytics.setUserProperty(stringValue, forName: firebaseKey)
            }
        }
    }
    
    /**
     * Handles track events
     * Extracted from Objective-C dump method's track handling
     */
    func track(payload: TrackEvent) {
        // Check if event name is present - equivalent to [RudderUtils isEmpty:eventName] check
        let eventName = payload.event
        guard !FirebaseUtils.isEmpty(eventName) else {
            LoggerAnalytics.debug("Since the event name is not present, the track event sent to Firebase has been dropped.")
            return
        }
        
        let properties = payload.properties?.dictionary
        
        // Handle special "Application Opened" event - equivalent to handleApplicationOpenedEvent
        if eventName == "Application Opened" {
            handleApplicationOpenedEvent(properties: properties)
        }
        // Handle ecommerce events - equivalent to ECOMMERCE_EVENTS_MAPPING check
        else if let firebaseEvent = FirebaseUtils.ecommerceEventsMapping[eventName] {
            handleECommerceEvent(eventName: eventName, firebaseEvent: firebaseEvent, properties: properties)
        }
        // Handle custom events - equivalent to handleCustomEvent
        else {
            handleCustomEvent(eventName: eventName, properties: properties)
        }
    }
    
    // MARK: - Private Track Event Handlers
    
    /**
     * Handles Application Opened event
     * Equivalent to Objective-C: handleApplicationOpenedEvent
     */
    private func handleApplicationOpenedEvent(properties: [String: Any]?) {
        let firebaseEvent = AnalyticsEventAppOpen
        var params: [String: Any] = [:]
        makeFirebaseEvent(firebaseEvent: firebaseEvent, params: &params, properties: properties, isECommerceEvent: false)
    }
    
    /**
     * Handles ecommerce events with mapping
     * Equivalent to Objective-C: handleECommerceEvent
     */
    private func handleECommerceEvent(eventName: String, firebaseEvent: String, properties: [String: Any]?) {
        var params: [String: Any] = [:]
        
        if let properties = properties {
            // Handle special parameter mappings for specific events
            handleSpecialECommerceParams(firebaseEvent: firebaseEvent, params: &params, properties: properties)
            
            // Add constant parameters for specific events
            addConstantParamsForECommerceEvent(params: &params, eventName: eventName)
            
            // Handle ecommerce-specific properties (revenue, products, currency, etc.)
            handleECommerceEventProperties(params: &params, properties: properties, firebaseEvent: firebaseEvent)
        }
        
        makeFirebaseEvent(firebaseEvent: firebaseEvent, params: &params, properties: properties, isECommerceEvent: true)
    }
    
    /**
     * Handles custom events
     * Equivalent to Objective-C: handleCustomEvent
     */
    private func handleCustomEvent(eventName: String, properties: [String: Any]?) {
        let firebaseEvent = FirebaseUtils.getTrimKey(eventName)
        var params: [String: Any] = [:]
        makeFirebaseEvent(firebaseEvent: firebaseEvent, params: &params, properties: properties, isECommerceEvent: false)
    }
    
    /**
     * Makes Firebase event with parameters
     * Equivalent to Objective-C: makeFirebaseEvent
     */
    private func makeFirebaseEvent(firebaseEvent: String, params: inout [String: Any], properties: [String: Any]?, isECommerceEvent: Bool) {
        attachAllCustomProperties(params: &params, properties: properties, isECommerceEvent: isECommerceEvent)
        LoggerAnalytics.debug("Logged \"\(firebaseEvent)\" to Firebase with properties: \(properties ?? [:])")
        FirebaseAnalytics.Analytics.logEvent(firebaseEvent, parameters: params)
    }
    
    /**
     * Handles special parameter mappings for ecommerce events
     * Equivalent to parts of Objective-C handleECommerceEvent method
     */
    private func handleSpecialECommerceParams(firebaseEvent: String, params: inout [String: Any], properties: [String: Any]) {
        // Handle share events
        if firebaseEvent == AnalyticsEventShare {
            if let cartId = properties["cart_id"], !FirebaseUtils.isEmpty(cartId) {
                params[AnalyticsParameterItemID] = cartId
            } else if let productId = properties["product_id"], !FirebaseUtils.isEmpty(productId) {
                params[AnalyticsParameterItemID] = productId
            }
        }
        
        // Handle promotion events
        if firebaseEvent == AnalyticsEventViewPromotion || firebaseEvent == AnalyticsEventSelectPromotion {
            if let name = properties["name"], !FirebaseUtils.isEmpty(name) {
                params[AnalyticsParameterPromotionName] = name
            }
        }
        
        // Handle select content events
        if firebaseEvent == AnalyticsEventSelectContent {
            if let productId = properties["product_id"], !FirebaseUtils.isEmpty(productId) {
                params[AnalyticsParameterItemID] = productId
            }
            params[AnalyticsParameterContentType] = "product"
        }
    }
    
    /**
     * Adds constant parameters for ecommerce events
     * Equivalent to Objective-C: addConstantParamsForECommerceEvent
     */
    private func addConstantParamsForECommerceEvent(params: inout [String: Any], eventName: String) {
        switch eventName {
        case FirebaseUtils.ECommProductShared:
            params[AnalyticsParameterContentType] = "product"
        case FirebaseUtils.ECommCartShared:
            params[AnalyticsParameterContentType] = "cart"
        default:
            break
        }
    }
    
    /**
     * Handles ecommerce-specific properties like revenue, products, currency
     * Equivalent to Objective-C: handleECommerceEventProperties
     */
    private func handleECommerceEventProperties(params: inout [String: Any], properties: [String: Any], firebaseEvent: String) {
        // Handle revenue/value mapping
        if let revenue = properties["revenue"], FirebaseUtils.isNumber(revenue) {
            params[AnalyticsParameterValue] = FirebaseUtils.doubleValue(revenue)
        } else if let value = properties["value"], FirebaseUtils.isNumber(value) {
            params[AnalyticsParameterValue] = FirebaseUtils.doubleValue(value)
        } else if let total = properties["total"], FirebaseUtils.isNumber(total) {
            params[AnalyticsParameterValue] = FirebaseUtils.doubleValue(total)
        }
        
        // Handle products array or root-level products
        if FirebaseUtils.eventWithProductsArray.contains(firebaseEvent), let products = properties["products"] {
            handleProducts(params: &params, properties: properties, isProductsArray: true)
        }
        
        if FirebaseUtils.eventWithProductsAtRoot.contains(firebaseEvent) {
            handleProducts(params: &params, properties: properties, isProductsArray: false)
        }
        
        // Handle currency
        if let currency = properties["currency"] {
            params[AnalyticsParameterCurrency] = "\(currency)"
        } else {
            params[AnalyticsParameterCurrency] = "USD"
        }
        
        // Handle ecommerce property mapping
        for (propertyKey, value) in properties {
            if let firebaseKey = FirebaseUtils.ecommercePropertyMapping[propertyKey], !FirebaseUtils.isEmpty(value) {
                params[firebaseKey] = "\(value)"
            }
        }
        
        // Handle shipping and tax
        if let shipping = properties["shipping"], FirebaseUtils.isNumber(shipping) {
            params[AnalyticsParameterShipping] = FirebaseUtils.doubleValue(shipping)
        }
        
        if let tax = properties["tax"], FirebaseUtils.isNumber(tax) {
            params[AnalyticsParameterTax] = FirebaseUtils.doubleValue(tax)
        }
        
        // Handle order_id mapping to transaction_id
        if let orderId = properties["order_id"] {
            params[AnalyticsParameterTransactionID] = "\(orderId)"
            // Backward compatibility
            params["order_id"] = "\(orderId)"
        }
    }
    
    /**
     * Handles products array or root-level product properties
     * Equivalent to Objective-C: handleProducts
     */
    private func handleProducts(params: inout [String: Any], properties: [String: Any], isProductsArray: Bool) {
        var mappedProducts: [[String: Any]] = []
        
        if isProductsArray {
            // Handle products array
            if let products = properties["products"] as? [[String: Any]] {
                for product in products {
                    var productBundle: [String: Any] = [:]
                    putProductValue(params: &productBundle, properties: product)
                    if !productBundle.isEmpty {
                        mappedProducts.append(productBundle)
                    }
                }
            }
        } else {
            // Handle product at root level
            var productBundle: [String: Any] = [:]
            putProductValue(params: &productBundle, properties: properties)
            if !productBundle.isEmpty {
                mappedProducts.append(productBundle)
            }
        }
        
        if !mappedProducts.isEmpty {
            params[AnalyticsParameterItems] = mappedProducts
        }
    }
    
    /**
     * Maps product properties to Firebase parameters
     * Equivalent to Objective-C: putProductValue
     */
    private func putProductValue(params: inout [String: Any], properties: [String: Any]) {
        for (key, firebaseKey) in FirebaseUtils.productPropertiesMapping {
            guard let value = properties[key], !FirebaseUtils.isEmpty(value) else { continue }
            
            switch firebaseKey {
            case AnalyticsParameterItemID, AnalyticsParameterItemName, AnalyticsParameterItemCategory:
                params[firebaseKey] = "\(value)"
            case AnalyticsParameterQuantity:
                if FirebaseUtils.isNumber(value) {
                    params[firebaseKey] = FirebaseUtils.intValue(value)
                }
            case AnalyticsParameterPrice:
                if FirebaseUtils.isNumber(value) {
                    params[firebaseKey] = FirebaseUtils.doubleValue(value)
                }
            default:
                break
            }
        }
    }
    
    /**
     * Attaches all custom properties to Firebase parameters
     * Equivalent to Objective-C: attachAllCustomProperties
     */
    private func attachAllCustomProperties(params: inout [String: Any], properties: [String: Any]?, isECommerceEvent: Bool) {
        guard let properties = properties, !properties.isEmpty else { return }
        
        for (key, value) in properties {
            let firebaseKey = FirebaseUtils.getTrimKey(key)
            
            // Skip reserved keywords for ecommerce events or empty values
            if (isECommerceEvent && FirebaseUtils.firebaseTrackReservedKeywords.contains(firebaseKey)) || FirebaseUtils.isEmpty(value) {
                continue
            }
            
            // Handle different value types
            if FirebaseUtils.isNumber(value) {
                params[firebaseKey] = FirebaseUtils.doubleValue(value)
            } else if let stringValue = value as? String {
                // Truncate strings longer than 100 characters
                let truncatedValue = stringValue.count > 100 ? String(stringValue.prefix(100)) : stringValue
                params[firebaseKey] = truncatedValue
            } else {
                let convertedString = "\(value)"
                // Only add if length is <= 100
                if convertedString.count <= 100 {
                    params[firebaseKey] = convertedString
                }
            }
        }
    }
    
    /**
     * Handles screen events
     * Extracted from Objective-C dump method's screen handling
     */
    func screen(payload: ScreenEvent) {
        // Check if screen name is present - equivalent to [RudderUtils isEmpty:screenName] check
        let screenName = payload.event
        guard !FirebaseUtils.isEmpty(screenName) else {
            LoggerAnalytics.debug("Since the event name is not present, the screen event sent to Firebase has been dropped.")
            return
        }
        
        // Create parameters dictionary and set screen name - equivalent to [params setValue:screenName forKey:kFIRParameterScreenName]
        var params: [String: Any] = [:]
        params[AnalyticsParameterScreenName] = screenName
        
        // Attach custom properties - equivalent to [self attachAllCustomProperties:params properties:message.properties isECommerceEvent:NO]
        attachAllCustomProperties(params: &params, properties: payload.properties?.dictionary, isECommerceEvent: false)
        
        // Log screen view event - equivalent to [FIRAnalytics logEventWithName:kFIREventScreenView parameters:params]
        LoggerAnalytics.debug("Logged screen view \"\(screenName)\" to Firebase with properties: \(payload.properties?.dictionary ?? [:])")
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
    }
}

