//
//  GridExportView.swift
//  MonoGrid
//
//  Pro Business Model - HD Export (1080x1080) for Instagram
//  Created on 2026-01-27.
//

import SwiftUI

/// HD 그리드 내보내기 화면 (1080x1080)
struct GridExportView: View {
    // MARK: - Properties

    let habit: Habit
    let completionData: [Date: Bool]
    let viewMode: GridViewMode
    let periodTitle: String
    let currentYear: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var exportedImage: UIImage?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Constants

    private let exportSize: CGFloat = 1080

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview Header
                Text("내보내기 미리보기")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Export Preview
                exportPreviewSection

                // Info Text
                Text("1080×1080 고해상도 이미지로 내보내기")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Export Button
                exportButton
            }
            .padding()
            .navigationTitle("이미지 내보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateExportImage()
            }
            .alert("내보내기 오류", isPresented: $showError) {
                Button("확인") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = exportedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Subviews

    private var exportPreviewSection: some View {
        ZStack {
            if isGenerating {
                ProgressView()
                    .frame(width: 300, height: 300)
            } else if let image = exportedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 300, height: 300)
                    .overlay {
                        Text("미리보기 생성 중...")
                            .foregroundColor(.secondary)
                    }
            }
        }
    }

    private var exportButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            showShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("이미지 저장/공유")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
            )
        }
        .disabled(exportedImage == nil || isGenerating)
        .opacity(exportedImage == nil || isGenerating ? 0.5 : 1)
    }

    // MARK: - Image Generation

    @MainActor
    private func generateExportImage() {
        isGenerating = true

        Task {
            do {
                let image = try await renderExportImage()
                self.exportedImage = image
                self.isGenerating = false
            } catch {
                self.isGenerating = false
                self.errorMessage = "이미지를 생성할 수 없습니다. 다시 시도해주세요."
                self.showError = true
            }
        }
    }

    @MainActor
    private func renderExportImage() async throws -> UIImage {
        // Create the exportable view
        let exportView = ExportableGridView(
            habitTitle: habit.title,
            habitColorHex: habit.colorHex,
            habitIconSymbol: habit.iconSymbol,
            periodTitle: periodTitle,
            completionData: completionData,
            viewMode: viewMode,
            currentYear: currentYear,
            exportSize: exportSize
        )

        // Use ImageRenderer for iOS 16+
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1.0 // We're already at 1080x1080

        guard let uiImage = renderer.uiImage else {
            throw ExportError.imageGenerationFailed
        }

        return uiImage
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case imageGenerationFailed

    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "이미지 생성에 실패했습니다"
        }
    }
}

// MARK: - Exportable Grid View

/// 내보내기용 그리드 뷰 (1080x1080)
struct ExportableGridView: View {
    let habitTitle: String
    let habitColorHex: String
    let habitIconSymbol: String
    let periodTitle: String
    let completionData: [Date: Bool]
    let viewMode: GridViewMode
    let currentYear: Int
    let exportSize: CGFloat

    private var habitColor: Color {
        Color(hex: habitColorHex)
    }

    var body: some View {
        ZStack {
            // Background
            Color.white

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 60)

                Spacer()

                // Grid
                gridSection

                Spacer()

                // Footer
                footerSection
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: exportSize, height: exportSize)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Habit Icon
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: habitIconSymbol)
                    .font(.system(size: 36))
                    .foregroundColor(habitColor)
            }

            // Habit Title
            Text(habitTitle)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)

            // Period Title
            Text(periodTitle)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Grid

    private var gridSection: some View {
        Group {
            switch viewMode {
            case .yearly:
                ExportYearlyGridView(
                    habitColorHex: habitColorHex,
                    year: currentYear,
                    completionData: completionData
                )
            case .monthly, .weekly:
                // For monthly/weekly, show yearly view in export
                ExportYearlyGridView(
                    habitColorHex: habitColorHex,
                    year: currentYear,
                    completionData: completionData
                )
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            // Statistics
            let stats = calculateStats()
            HStack(spacing: 40) {
                statItem(value: "\(stats.completed)", label: "완료")
                statItem(value: "\(stats.rate)%", label: "달성률")
                statItem(value: "\(stats.streak)", label: "연속")
            }

            // App Branding
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 14))
                Text("MonoGrid")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.gray.opacity(0.6))
            .padding(.top, 16)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }

    private func calculateStats() -> (completed: Int, rate: Int, streak: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Count completed days
        let completed = completionData.values.filter { $0 }.count

        // Calculate rate (for the current year up to today)
        let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let endDate = min(today, calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))!)
        let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endDate).day! + 1
        let rate = totalDays > 0 ? Int(Double(completed) / Double(totalDays) * 100) : 0

        // Calculate current streak
        var streak = 0
        var currentDate = today
        while true {
            if let isCompleted = completionData[currentDate], isCompleted {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return (completed, rate, streak)
    }
}

// MARK: - Export Yearly Grid View

/// 내보내기용 연간 그리드 (GitHub 스타일)
struct ExportYearlyGridView: View {
    let habitColorHex: String
    let year: Int
    let completionData: [Date: Bool]

    private let cellSize: CGFloat = 14
    private let cellGap: CGFloat = 3
    private let rowCount = 7

    private var habitColor: Color {
        Color(hex: habitColorHex)
    }

    private var weekColumns: [[Date]] {
        let calendar = Calendar.current
        let dates = DateRangeCalculator.datesInYear(year)
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []

        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 2 && !currentWeek.isEmpty {
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(date)
        }

        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        return weeks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            monthLabelsView

            // Grid
            HStack(alignment: .top, spacing: 0) {
                dayLabelsView
                gridView
            }
        }
    }

    private var monthLabelsView: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 30)

            HStack(spacing: 0) {
                ForEach(monthLabels, id: \.weekIndex) { label in
                    Text(label.name)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: CGFloat(label.weekCount) * (cellSize + cellGap), alignment: .leading)
                }
            }
        }
    }

    private var monthLabels: [(name: String, weekIndex: Int, weekCount: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"

        var labels: [(String, Int, Int)] = []
        var currentMonth = 0
        var monthStartWeek = 0

        for (weekIndex, week) in weekColumns.enumerated() {
            if let firstDay = week.first {
                let month = calendar.component(.month, from: firstDay)
                if month != currentMonth {
                    if currentMonth != 0 {
                        labels.append((formatter.string(from: calendar.date(from: DateComponents(year: year, month: currentMonth, day: 1))!), monthStartWeek, weekIndex - monthStartWeek))
                    }
                    currentMonth = month
                    monthStartWeek = weekIndex
                }
            }
        }

        // Add last month
        if currentMonth != 0 {
            labels.append((formatter.string(from: calendar.date(from: DateComponents(year: year, month: currentMonth, day: 1))!), monthStartWeek, weekColumns.count - monthStartWeek))
        }

        return labels
    }

    private var dayLabelsView: some View {
        VStack(spacing: cellGap) {
            ForEach(0..<rowCount, id: \.self) { dayIndex in
                Text(dayLabel(for: dayIndex))
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: cellSize, alignment: .trailing)
            }
        }
    }

    private func dayLabel(for index: Int) -> String {
        switch index {
        case 0: return "월"
        case 2: return "수"
        case 4: return "금"
        default: return ""
        }
    }

    private var gridView: some View {
        HStack(spacing: cellGap) {
            ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                weekColumn(for: week)
            }
        }
    }

    private func weekColumn(for dates: [Date]) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return VStack(spacing: cellGap) {
            let firstWeekday = calendar.component(.weekday, from: dates.first ?? Date())
            let mondayBasedWeekday = (firstWeekday + 5) % 7

            ForEach(0..<rowCount, id: \.self) { dayIndex in
                if dayIndex < mondayBasedWeekday && dates == weekColumns.first {
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                } else {
                    let dateIndex = dayIndex - (dates == weekColumns.first ? mondayBasedWeekday : 0)
                    if dateIndex >= 0 && dateIndex < dates.count {
                        let date = dates[dateIndex]
                        let normalizedDate = calendar.startOfDay(for: date)
                        let isCompleted = completionData[normalizedDate]
                        let isFuture = normalizedDate > today

                        cellView(isCompleted: isCompleted, isFuture: isFuture)
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func cellView(isCompleted: Bool?, isFuture: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor(isCompleted: isCompleted, isFuture: isFuture))
            .frame(width: cellSize, height: cellSize)
    }

    private func cellColor(isCompleted: Bool?, isFuture: Bool) -> Color {
        if isFuture {
            return Color(hex: "#F5F5F5")
        }
        guard let completed = isCompleted else {
            return Color(hex: "#EBEDF0")
        }
        return completed ? habitColor : Color(hex: "#EBEDF0")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let sampleData: [Date: Bool] = {
        var data: [Date: Bool] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<365 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                data[date] = Bool.random()
            }
        }
        return data
    }()

    return GridExportView(
        habit: Habit(title: "독서", colorHex: "#4D96FF", iconSymbol: "book.fill"),
        completionData: sampleData,
        viewMode: .yearly,
        periodTitle: "2026년",
        currentYear: 2026
    )
}
