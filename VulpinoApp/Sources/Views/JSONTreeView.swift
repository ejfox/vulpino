import SwiftUI

/// A view for displaying and selecting keys from a JSON structure
struct JSONTreeView: View {
    let nodes: [APIService.JSONNode]
    @Binding var selectedPaths: Set<String>
    let maxSelections: Int

    @State private var expandedPaths: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(nodes) { node in
                JSONNodeRow(
                    node: node,
                    selectedPaths: $selectedPaths,
                    expandedPaths: $expandedPaths,
                    maxSelections: maxSelections
                )
            }
        }
    }
}

struct JSONNodeRow: View {
    let node: APIService.JSONNode
    @Binding var selectedPaths: Set<String>
    @Binding var expandedPaths: Set<String>
    let maxSelections: Int

    private var isExpanded: Bool {
        expandedPaths.contains(node.path)
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

    var body: some View {
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
                            if isExpanded {
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
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                // Key name
                Text(node.key)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(hasChildren ? .medium : .regular)

                Spacer()

                // Value preview
                if node.value.isPrimitive {
                    Text(node.displayValue)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
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
                            .foregroundStyle(isSelected ? .blue : (canSelect ? .secondary : .quaternary))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSelect)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if hasChildren {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
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
                        maxSelections: maxSelections
                    )
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
