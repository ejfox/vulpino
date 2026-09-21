import SwiftUI

/// A view for displaying and selecting keys from a JSON structure
struct JSONTreeView: View {
    let nodes: [APIService.JSONNode]
    @Binding var selectedPaths: Set<String>
    let maxSelections: Int

    @State private var expandedPaths: Set<String> = []
    @State private var searchText: String = ""

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var searchQuery: String {
        searchText.lowercased().trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search keys or values...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Expand/Collapse controls
            HStack {
                Button {
                    expandAll(nodes)
                } label: {
                    Text("Expand All")
                        .font(.caption)
                }

                Text("•")
                    .foregroundStyle(.quaternary)

                Button {
                    expandedPaths.removeAll()
                } label: {
                    Text("Collapse All")
                        .font(.caption)
                }

                Spacer()

                if isSearching {
                    Text("Matching paths expanded")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Tree view
            ForEach(nodes) { node in
                JSONNodeRow(
                    node: node,
                    selectedPaths: $selectedPaths,
                    expandedPaths: $expandedPaths,
                    maxSelections: maxSelections,
                    searchQuery: searchQuery
                )
            }
        }
        .onAppear {
            // Auto-expand first 2 levels
            autoExpandLevels(nodes, maxDepth: 2)
        }
    }

    private func expandAll(_ nodes: [APIService.JSONNode]) {
        for node in nodes {
            if node.children != nil {
                expandedPaths.insert(node.path)
                if let children = node.children {
                    expandAll(children)
                }
            }
        }
    }

    private func autoExpandLevels(_ nodes: [APIService.JSONNode], maxDepth: Int) {
        for node in nodes {
            if node.depth < maxDepth, node.children != nil {
                expandedPaths.insert(node.path)
                if let children = node.children {
                    autoExpandLevels(children, maxDepth: maxDepth)
                }
            }
        }
    }
}

struct JSONNodeRow: View {
    let node: APIService.JSONNode
    @Binding var selectedPaths: Set<String>
    @Binding var expandedPaths: Set<String>
    let maxSelections: Int
    var searchQuery: String = ""

    private var isSearching: Bool {
        !searchQuery.isEmpty
    }

    private var matchesSearch: Bool {
        guard isSearching else { return false }
        return node.key.lowercased().contains(searchQuery) ||
               node.displayValue.lowercased().contains(searchQuery) ||
               node.path.lowercased().contains(searchQuery)
    }

    private var hasMatchingDescendant: Bool {
        guard isSearching, let children = node.children else { return false }
        return children.contains { child in
            child.key.lowercased().contains(searchQuery) ||
            child.displayValue.lowercased().contains(searchQuery) ||
            childHasMatch(child)
        }
    }

    private func childHasMatch(_ node: APIService.JSONNode) -> Bool {
        guard let children = node.children else { return false }
        return children.contains { child in
            child.key.lowercased().contains(searchQuery) ||
            child.displayValue.lowercased().contains(searchQuery) ||
            childHasMatch(child)
        }
    }

    private var isExpanded: Bool {
        // Auto-expand when searching and has matching descendants
        (isSearching && hasMatchingDescendant) || expandedPaths.contains(node.path)
    }

    private var shouldShow: Bool {
        // Show if matches, has matching descendant, or not searching
        !isSearching || matchesSearch || hasMatchingDescendant
    }

    private var isSelected: Bool {
        selectedPaths.contains(node.path)
    }

    private var canSelect: Bool {
        node.value.isPrimitive && (isSelected || selectedPaths.count < maxSelections)
    }

    private var hasChildren: Bool {
        node.children != nil && !(node.children?.isEmpty ?? true)
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else if matchesSearch {
            return Color.yellow.opacity(0.2)
        }
        return Color.clear
    }

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    // Indentation
                    ForEach(0..<node.depth, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20)
                    }

                    // Expand/collapse button or spacer
                    if hasChildren {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if expandedPaths.contains(node.path) {
                                    expandedPaths.remove(node.path)
                                } else {
                                    expandedPaths.insert(node.path)
                                }
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16)
                    }

                    // Type icon
                    Image(systemName: node.typeIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(matchesSearch ? .orange : .secondary)
                        .frame(width: 16)

                    // Key name
                    Text(node.key)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(hasChildren ? .medium : .regular)
                        .foregroundStyle(matchesSearch ? .primary : .primary)

                    Spacer()

                    // Value preview
                    if node.value.isPrimitive {
                        Text(node.displayValue)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(matchesSearch ? .primary : .secondary)
                            .lineLimit(1)
                    } else {
                        Text(node.displayValue)
                            .font(.system(.caption2))
                            .foregroundStyle(.tertiary)
                    }

                    // Selection checkbox for primitives
                    if node.value.isPrimitive {
                        Button {
                            if isSelected {
                                selectedPaths.remove(node.path)
                            } else if canSelect {
                                selectedPaths.insert(node.path)
                            }
                        } label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(isSelected ? AnyShapeStyle(Color.blue) : (canSelect ? AnyShapeStyle(.secondary) : AnyShapeStyle(.quaternary)))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSelect)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(rowBackground)
                .contentShape(Rectangle())
                .onTapGesture {
                    if hasChildren {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if expandedPaths.contains(node.path) {
                                expandedPaths.remove(node.path)
                            } else {
                                expandedPaths.insert(node.path)
                            }
                        }
                    } else if node.value.isPrimitive && canSelect {
                        if isSelected {
                            selectedPaths.remove(node.path)
                        } else {
                            selectedPaths.insert(node.path)
                        }
                    }
                }

                Divider()
                    .padding(.leading, CGFloat(node.depth * 20 + 48))

                // Children
                if hasChildren && isExpanded, let children = node.children {
                    ForEach(children) { child in
                        JSONNodeRow(
                            node: child,
                            selectedPaths: $selectedPaths,
                            expandedPaths: $expandedPaths,
                            maxSelections: maxSelections,
                            searchQuery: searchQuery
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleJSON = JSONValue.object([
        "data": .object([
            "visitors": .number(12847),
            "pageViews": .number(34521),
            "bounceRate": .number(34.5)
        ]),
        "status": .string("healthy"),
        "items": .array([
            .object(["name": .string("Item 1"), "count": .number(42)]),
            .object(["name": .string("Item 2"), "count": .number(17)])
        ])
    ])

    let nodes = APIService.shared.buildStructure(from: sampleJSON)

    return ScrollView {
        JSONTreeView(
            nodes: nodes,
            selectedPaths: .constant(["data.visitors"]),
            maxSelections: 5
        )
    }
}
