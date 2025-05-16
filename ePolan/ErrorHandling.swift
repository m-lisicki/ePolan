//
//  ViewState.swift
//  ePolan
//
//  Created by Michał Lisicki on 17/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

enum ViewState {
    case loading
    case loaded
    case empty
    case offlineNotLoaded
}

@MainActor
protocol FallbackView {
    associatedtype T: Hashable

    var networkMonitor: NetworkMonitor { get }
    var apiError: ApiError? { get }
    var showApiError: Bool { get set }
    var data: Set<T>? { get }
}

extension FallbackView {
    @MainActor
    var viewState: ViewState {
        if !networkMonitor.isConnected && data != nil {
            return .offlineNotLoaded
        } else if data == nil {
            return .loading
        } else if data?.isEmpty ?? false {
            return .empty
        } else {
            return .loaded
        }
    }
}

// MARK: - Error Handling

enum ApiError: Error {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case requestError(Error)
    case customError(String)
}

extension ApiError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response format"
        case .httpError(statusCode: let code, body: let message):
            return "HTTP error \(code): \(message)"
        case .requestError(let underlyingError):
            return underlyingError.localizedDescription
        case .customError(let message):
            return message
        }
    }
}

extension Error {
    func mapToApiError() -> ApiError {
        if let apiError = self as? ApiError {
            return apiError
        } else {
            return .customError("Unexpected error: \(self.localizedDescription)")
        }
    }
}

extension View {
    func fallbackView(viewState: ViewState, fetchData: @escaping (_ forceRefresh: Bool) async -> Void) -> some View {
        overlay {
            switch viewState {
            case .loading:
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                
            case .empty:
                ContentUnavailableView("No items yet", systemImage: "book.closed")
                
            case .offlineNotLoaded:
                ContentUnavailableView {
                    Label("No Internet Connection", systemImage: "wifi.slash")
                } description: {
                    Text("Check your internet connection and try again.")
                }
                
            case .loaded:
                EmptyView()
            }
        }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, error: ApiError?) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(title: Text("Something went wrong!"), message: Text(error?.localizedDescription ?? "An unknown error occurred."))
        }
    }
}
