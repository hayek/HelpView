//
//  ContentView.swift
//  HelpViewExample
//
//  Created by Amir hayek on 08/10/2025.
//

import SwiftUI
import HelpView

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Welcome to HelpView Demo")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("This example demonstrates both ways to integrate the HelpView SDK.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                } header: {
                    Text("HelpView SDK Demo")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "sparkles", title: "AI-Powered Help", description: "Uses Apple Intelligence when available")
                        FeatureRow(icon: "magnifyingglass", title: "Smart Search", description: "Falls back to search on other devices")
                        FeatureRow(icon: "doc.text", title: "Markdown Support", description: "Rich formatted answers")
                        FeatureRow(icon: "folder", title: "Topic Organization", description: "Grouped by categories")
                    }
                } header: {
                    Text("Features")
                }

                Section {
                    // Example 1: Button with sheet (toolbar)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Button with Sheet", systemImage: "questionmark.circle")
                            .font(.headline)
                        Text("See the question mark button in the toolbar above")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    // Example 2: Embeddable content view (NavigationLink)
                    NavigationLink {
                        HelpContentView(named: "app_help")
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Embeddable Content View", systemImage: "arrow.right.square")
                                .font(.headline)
                            Text("Tap to navigate to help content directly")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Integration Examples")
                } footer: {
                    Text("The SDK provides two APIs: a ready-to-use button (HelpViewButton) and an embeddable content view (HelpContentView) for custom navigation flows.")
                }
            }
            .navigationTitle("HelpView Demo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HelpViewButton(named: "app_help")
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
