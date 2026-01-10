import SwiftUI

/// Grid of template previews for selection
struct TemplatePickerView: View {
    @Binding var selectedTemplate: WidgetTemplate
    let previewData: WidgetDisplayData

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(WidgetTemplate.allCases) { template in
                    TemplatePreviewCard(
                        template: template,
                        data: previewData,
                        isSelected: selectedTemplate == template
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTemplate = template
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct TemplatePreviewCard: View {
    let template: WidgetTemplate
    let data: WidgetDisplayData
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview
            TemplateRenderer(template: template, data: data)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

            // Label
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(template.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                }

                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Size Picker

struct SizePickerView: View {
    @Binding var selectedSize: WidgetSize
    let availableSizes: [WidgetSize]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(WidgetSize.allCases) { size in
                SizeButton(
                    size: size,
                    isSelected: selectedSize == size,
                    isAvailable: availableSizes.contains(size)
                )
                .onTapGesture {
                    if availableSizes.contains(size) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSize = size
                        }
                    }
                }
            }
        }
    }
}

struct SizeButton: View {
    let size: WidgetSize
    let isSelected: Bool
    let isAvailable: Bool

    private var aspectRatio: CGFloat {
        switch size {
        case .small: return 1.0
        case .medium: return 2.0
        case .large: return 1.0
        }
    }

    private var baseWidth: CGFloat {
        switch size {
        case .small: return 50
        case .medium: return 80
        case .large: return 60
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .frame(width: baseWidth, height: baseWidth / aspectRatio)
                .opacity(isAvailable ? 1 : 0.4)

            Text(size.gridDescription)
                .font(.caption2)
                .foregroundStyle(isSelected ? .blue : .secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    TemplatePickerView(
        selectedTemplate: .constant(.monoStat),
        previewData: WidgetDisplayData(
            values: [
                ("visitors", "12,847"),
                ("bounce", "34%"),
                ("time", "2:41")
            ]
        )
    )
}
