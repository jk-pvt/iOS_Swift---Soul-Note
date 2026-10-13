import SwiftUI

// MARK: - Heritage Date Picker Sheet

/// A fully custom date picker styled to match SoulNote's dark archival aesthetic.
/// Drop-in replacement for the system DatePicker graphical sheet.
struct HeritageDatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDone: () -> Void

    @State private var displayedMonth: Date
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    init(selectedDate: Binding<Date>, onDone: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onDone = onDone
        // Start display on the currently selected (or today's) month
        let start = selectedDate.wrappedValue >= Date() ? selectedDate.wrappedValue : Date()
        self._displayedMonth = State(initialValue: Calendar.current.startOfMonth(for: start))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.archiveBackground.ignoresSafeArea()
                FilmGrainTexture(opacity: 0.06).ignoresSafeArea().blendMode(.softLight)

                VStack(spacing: 0) {
                    monthHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    weekdayRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    Divider()
                        .background(DesignTokens.archiveBrown.opacity(0.2))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    dayGrid
                        .padding(.horizontal, 12)

                    Spacer()

                    if selectedDate >= Date() {
                        selectedSummary
                            .padding(.bottom, 24)
                    }

                    Button {
                        onDone()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Seal the Date")
                                .font(.system(size: 17, weight: .medium))
                            Image(systemName: "seal.fill")
                                .font(.system(size: 15, weight: .light))
                        }
                        .foregroundColor(DesignTokens.archiveBackground)
                        .padding(.horizontal, 36)
                        .frame(height: 56)
                        .frame(minWidth: 220, maxWidth: 340)
                        .background(
                            Capsule()
                                .fill(DesignTokens.amberGradient)
                                .shadow(color: DesignTokens.amberGlow.opacity(0.4), radius: 18, x: 0, y: 0)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Choose a Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                HapticService.shared.light()
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoBack ? .white.opacity(0.8) : .white.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(canGoBack ? 0.08 : 0.03)))
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString(displayedMonth))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(.white)

                let year = calendar.component(.year, from: displayedMonth)
                let currentYear = calendar.component(.year, from: Date())
                if year > currentYear {
                    Text("In \(year - currentYear) year\(year - currentYear == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(DesignTokens.amberGlow.opacity(0.8))
                }
            }

            Spacer()

            Button {
                HapticService.shared.light()
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1)
                    .foregroundColor(DesignTokens.archiveBrown.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isPast = date < calendar.startOfDay(for: Date())
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let day = calendar.component(.day, from: date)

        Button {
            guard !isPast else { return }
            HapticService.shared.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedDate = date
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(DesignTokens.amberGradient)
                        .shadow(color: DesignTokens.amberGlow.opacity(0.5), radius: 8)
                } else if isToday {
                    Circle()
                        .stroke(DesignTokens.amberGlow.opacity(0.5), lineWidth: 1.5)
                }

                Text("\(day)")
                    .font(.system(
                        size: 15,
                        weight: isSelected ? .semibold : (isToday ? .medium : .regular)
                    ))
                    .foregroundColor(
                        isSelected ? DesignTokens.archiveBackground :
                        isPast ? .white.opacity(0.18) :
                        isToday ? DesignTokens.amberGlow :
                        .white.opacity(0.85)
                    )
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isPast)
    }

    // MARK: - Selected Summary

    private var selectedSummary: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.amberGlow)

            Text("This letter opens on \(selectedDate.formatted(date: .long, time: .omitted))")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignTokens.amberGlow.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var canGoBack: Bool {
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return false }
        return calendar.startOfMonth(for: Date()) <= displayedMonth
            && calendar.startOfMonth(for: Date()) < displayedMonth
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstDay) - 1

        var cells: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
