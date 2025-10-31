//
//  FirebaseUtils.swift
//  FirebaseSampleIntegration
//
//  Created by Vishal Gupta on 30/10/25.
//

import Foundation
import FirebaseAnalytics

/**
 * Firebase Utilities for RudderStack Firebase Integration
 * 
 * This class contains constants, mappings, and helper methods for the Firebase integration.
 * Equivalent to RudderUtils in the Objective-C version.
 */
class FirebaseUtils {
    
    // MARK: - Reserved Keywords
    
    /// Reserved keywords for identify events - equivalent to IDENTIFY_RESERVED_KEYWORDS
    static let identifyReservedKeywords: Set<String> = ["age", "gender", "interest"]
    
    /// Reserved keywords for track events - equivalent to FIREBASE_TRACK_RESERVED_KEYWORDS
    static let firebaseTrackReservedKeywords: Set<String> = [
        "product_id", "name", "category", "quantity", "price", "currency", "value", "revenue", 
        "total", "tax", "shipping", "coupon", "cart_id", "payment_method", "query", "list_id", 
        "promotion_id", "creative", "affiliation", "share_via", "products", "order_id", 
        AnalyticsParameterScreenName
    ]
    
    // MARK: - Ecommerce Event Mapping
    
    /// Ecommerce events mapping - equivalent to ECOMMERCE_EVENTS_MAPPING
    static let ecommerceEventsMapping: [String: String] = [
        ECommPaymentInfoEntered: AnalyticsEventAddPaymentInfo,
        ECommProductAdded: AnalyticsEventAddToCart,
        ECommProductAddedToWishList: AnalyticsEventAddToWishlist,
        ECommCheckoutStarted: AnalyticsEventBeginCheckout,
        ECommOrderCompleted: AnalyticsEventPurchase,
        ECommOrderRefunded: AnalyticsEventRefund,
        ECommProductsSearched: AnalyticsEventSearch,
        ECommCartShared: AnalyticsEventShare,
        ECommProductShared: AnalyticsEventShare,
        ECommProductViewed: AnalyticsEventViewItem,
        ECommProductListViewed: AnalyticsEventViewItemList,
        ECommProductRemoved: AnalyticsEventRemoveFromCart,
        ECommProductClicked: AnalyticsEventSelectContent,
        ECommPromotionViewed: AnalyticsEventViewPromotion,
        ECommPromotionClicked: AnalyticsEventSelectPromotion,
        ECommCartViewed: AnalyticsEventViewCart
    ]
    
    // MARK: - Product Properties Mapping
    
    /// Product properties mapping - equivalent to PRODUCT_PROPERTIES_MAPPING
    static let productPropertiesMapping: [String: String] = [
        "product_id": AnalyticsParameterItemID,
        "name": AnalyticsParameterItemName,
        "category": AnalyticsParameterItemCategory,
        "quantity": AnalyticsParameterQuantity,
        "price": AnalyticsParameterPrice
    ]
    
    // MARK: - Events with Products
    
    /// Events that support products array - equivalent to EVENT_WITH_PRODUCTS_ARRAY
    static let eventWithProductsArray: Set<String> = [
        AnalyticsEventBeginCheckout,
        AnalyticsEventPurchase,
        AnalyticsEventRefund,
        AnalyticsEventViewItemList,
        AnalyticsEventViewCart
    ]
    
    /// Events that support products at root level - equivalent to EVENT_WITH_PRODUCTS_AT_ROOT
    static let eventWithProductsAtRoot: Set<String> = [
        AnalyticsEventAddToCart,
        AnalyticsEventAddToWishlist,
        AnalyticsEventViewItem,
        AnalyticsEventRemoveFromCart
    ]
    
    // MARK: - Ecommerce Property Mapping
    
    /// Ecommerce property mapping - equivalent to ECOMMERCE_PROPERTY_MAPPING
    static let ecommercePropertyMapping: [String: String] = [
        "payment_method": AnalyticsParameterPaymentType,
        "coupon": AnalyticsParameterCoupon,
        "query": AnalyticsParameterSearchTerm,
        "list_id": AnalyticsParameterItemListID,
        "promotion_id": AnalyticsParameterPromotionID,
        "creative": AnalyticsParameterCreativeName,
        "affiliation": AnalyticsParameterAffiliation,
        "share_via": AnalyticsParameterMethod
    ]
    
    // MARK: - Ecommerce Event Constants
    
    /// Ecommerce event name constants
    static let ECommPaymentInfoEntered = "Payment Info Entered"
    static let ECommProductAdded = "Product Added"
    static let ECommProductAddedToWishList = "Product Added to Wishlist"
    static let ECommCheckoutStarted = "Checkout Started"
    static let ECommOrderCompleted = "Order Completed"
    static let ECommOrderRefunded = "Order Refunded"
    static let ECommProductsSearched = "Products Searched"
    static let ECommCartShared = "Cart Shared"
    static let ECommProductShared = "Product Shared"
    static let ECommProductViewed = "Product Viewed"
    static let ECommProductListViewed = "Product List Viewed"
    static let ECommProductRemoved = "Product Removed"
    static let ECommProductClicked = "Product Clicked"
    static let ECommPromotionViewed = "Promotion Viewed"
    static let ECommPromotionClicked = "Promotion Clicked"
    static let ECommCartViewed = "Cart Viewed"
    
    // MARK: - Helper Methods
    
    /**
     * Trims and formats a key for Firebase
     * Equivalent to Objective-C: getTrimKey
     */
    static func getTrimKey(_ key: String) -> String {
        let trimmedKey = key.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        
        // Limit to 40 characters (Firebase parameter name limit)
        let maxLength = 40
        if trimmedKey.count > maxLength {
            return String(trimmedKey.prefix(maxLength))
        }
        
        return trimmedKey
    }
    
    /**
     * Checks if a value is empty
     * Equivalent to Objective-C: isEmpty
     */
    static func isEmpty(_ value: Any?) -> Bool {
        if value == nil {
            return true
        }
        
        if let stringValue = value as? String {
            return stringValue.isEmpty
        }
        
        if let dictValue = value as? [String: Any] {
            return dictValue.isEmpty
        }
        
        if let arrayValue = value as? [Any] {
            return arrayValue.isEmpty
        }
        
        return false
    }
    
    /**
     * Checks if a value is a number
     * Equivalent to Objective-C: isNumber
     */
    static func isNumber(_ value: Any?) -> Bool {
        if value is NSNumber {
            return true
        }
        
        if let stringValue = value as? String {
            return Double(stringValue) != nil
        }
        
        return false
    }
    
    /**
     * Converts a value to Double
     * Helper method for numeric conversions
     */
    static func doubleValue(_ value: Any) -> Double {
        if let numberValue = value as? NSNumber {
            return numberValue.doubleValue
        }
        
        if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return doubleValue
        }
        
        return 0.0
    }
    
    /**
     * Converts a value to Int
     * Helper method for numeric conversions
     */
    static func intValue(_ value: Any) -> Int {
        if let numberValue = value as? NSNumber {
            return numberValue.intValue
        }
        
        if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        
        return 0
    }
}

