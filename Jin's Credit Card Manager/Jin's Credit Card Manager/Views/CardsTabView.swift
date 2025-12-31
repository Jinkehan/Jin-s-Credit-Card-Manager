//
//  CardsTabView.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI

struct CardsTabView: View {
    @Bindable var viewModel: CardViewModel
    @State private var isAddingCard = false
    @State private var editingCard: CreditCard?
    @State private var cardToDelete: CreditCard?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("My Cards")
                            .font(.system(size: 34, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingCard = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Cards List
                if viewModel.cards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("No cards added yet")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                        
                        Text("Tap the + button to add your first card")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.cards, id: \.id) { card in
                            CardItemView(card: card, onDelete: {
                                cardToDelete = card
                                showDeleteConfirmation = true
                            }, onTap: {
                                editingCard = card
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Delete Card", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card)
                    cardToDelete = nil
                }
            }
        } message: {
            if let card = cardToDelete {
                Text("Are you sure you want to delete \"\(card.name)\"? This action cannot be undone.")
            }
        }
        .sheet(isPresented: $isAddingCard) {
            AddCardView(viewModel: viewModel, isPresented: $isAddingCard)
        }
        .sheet(item: $editingCard) { card in
            EditCardView(viewModel: viewModel, card: card, isPresented: Binding(
                get: { editingCard != nil },
                set: { if !$0 { editingCard = nil } }
            ))
        }
    }
}

struct CardItemView: View {
    let card: CreditCard
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardContent: some View {
        HStack(spacing: 12) {
            // Card image
            CardImageView(card: card)
            
            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !card.lastFourDigits.isEmpty {
                    Text(card.lastFourDigits)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct AddCardView: View {
    @Bindable var viewModel: CardViewModel
    @Binding var isPresented: Bool
    
    @ObservedObject private var benefitsService = CardBenefitsService.shared
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var selectedDate = Date()
    @State private var isLastDayOfMonth = false
    @State private var reminderDaysAhead = 5
    @State private var selectedPredefinedCard: PredefinedCard?
    @State private var showCardPicker = false
    
    private var dueDateDay: Int {
        if isLastDayOfMonth {
            return 0
        }
        return Calendar.current.component(.day, from: selectedDate)
    }
    
    private var dueDateDescription: String {
        if isLastDayOfMonth {
            return "last day"
        } else {
            let day = Calendar.current.component(.day, from: selectedDate)
            return "\(day)\(getOrdinalSuffix(day))"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    // Card Type Selection Row
                    Button(action: {
                        showCardPicker = true
                    }) {
                        HStack {
                            Text("Card Type")
                                .foregroundColor(.primary)
                            Spacer()
                            if let predefinedCard = selectedPredefinedCard {
                                Text("\(predefinedCard.name)")
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            } else {
                                Text("Custom")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    TextField("Card Name", text: $cardName)
                        .autocapitalization(.words)
                    
                    TextField("Last 4 Digits (Optional)", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { oldValue, newValue in
                            lastFourDigits = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    
                    Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                    
                    if !isLastDayOfMonth {
                        DatePicker(
                            "Due Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Text("Payment due on the \(dueDateDescription) of each month")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Reminder Settings")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remind me \(reminderDaysAhead) day\(reminderDaysAhead == 1 ? "" : "s") before due date")
                            .font(.system(size: 14, weight: .medium))
                        
                        Slider(
                            value: Binding(
                                get: { Double(reminderDaysAhead) },
                                set: { reminderDaysAhead = Int($0) }
                            ),
                            in: 1...30,
                            step: 1
                        )
                        .accentColor(.blue)
                        
                        HStack {
                            Text("1 day")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("30 days")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !cardName.isEmpty {
                            viewModel.addCard(
                                name: cardName,
                                lastFourDigits: lastFourDigits,
                                dueDate: dueDateDay,
                                reminderDaysAhead: reminderDaysAhead,
                                predefinedCardId: selectedPredefinedCard?.id,
                                cardAnniversaryDate: Date()
                            )
                            isPresented = false
                        }
                    }
                    .disabled(cardName.isEmpty)
                }
            }
            .task {
                await benefitsService.fetchCardBenefits()
            }
            .sheet(isPresented: $showCardPicker) {
                CardPickerView(
                    selectedCard: $selectedPredefinedCard,
                    isPresented: $showCardPicker,
                    onCardSelected: { predefinedCard in
                        selectedPredefinedCard = predefinedCard
                        // Update card name when a predefined card is selected
                        if let predefined = predefinedCard {
                            cardName = predefined.name
                        }
                    }
                )
            }
        }
    }
    
    private func getOrdinalSuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

struct EditCardView: View {
    @Bindable var viewModel: CardViewModel
    let card: CreditCard
    @Binding var isPresented: Bool
    
    @ObservedObject private var benefitsService = CardBenefitsService.shared
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var selectedDate = Date()
    @State private var isLastDayOfMonth = false
    @State private var reminderDaysAhead = 5
    @State private var showBenefits = false
    @State private var selectedPredefinedCard: PredefinedCard?
    @State private var showCardPicker = false
    
    init(viewModel: CardViewModel, card: CreditCard, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.card = card
        self._isPresented = isPresented
        
        // Initialize state with card values
        self._cardName = State(initialValue: card.name)
        self._lastFourDigits = State(initialValue: card.lastFourDigits)
        self._isLastDayOfMonth = State(initialValue: card.isLastDayOfMonth)
        self._reminderDaysAhead = State(initialValue: card.reminderDaysAhead)
        
        // Initialize selected predefined card if the card has one
        if let predefinedCardId = card.predefinedCardId {
            self._selectedPredefinedCard = State(initialValue: CardBenefitsService.shared.getPredefinedCard(byId: predefinedCardId))
        }
        
        // Set initial date
        if !card.isLastDayOfMonth {
            let calendar = Calendar.current
            let components = DateComponents(year: 2024, month: 1, day: card.dueDate)
            self._selectedDate = State(initialValue: calendar.date(from: components) ?? Date())
        }
    }
    
    private var dueDateDay: Int {
        if isLastDayOfMonth {
            return 0
        }
        return Calendar.current.component(.day, from: selectedDate)
    }
    
    private var dueDateDescription: String {
        if isLastDayOfMonth {
            return "last day"
        } else {
            let day = Calendar.current.component(.day, from: selectedDate)
            return "\(day)\(getOrdinalSuffix(day))"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    // Card Type Selection Row
                    Button(action: {
                        showCardPicker = true
                    }) {
                        HStack {
                            Text("Card Type")
                                .foregroundColor(.primary)
                            Spacer()
                            if let predefinedCard = selectedPredefinedCard {
                                Text("\(predefinedCard.name)")
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            } else {
                                Text("Custom")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    TextField("Card Name", text: $cardName)
                        .autocapitalization(.words)
                    
                    TextField("Last 4 Digits (Optional)", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { oldValue, newValue in
                            lastFourDigits = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    
                    Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                    
                    if !isLastDayOfMonth {
                        DatePicker(
                            "Due Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Text("Payment due on the \(dueDateDescription) of each month")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Reminder Settings")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remind me \(reminderDaysAhead) day\(reminderDaysAhead == 1 ? "" : "s") before due date")
                            .font(.system(size: 14, weight: .medium))
                        
                        Slider(
                            value: Binding(
                                get: { Double(reminderDaysAhead) },
                                set: { reminderDaysAhead = Int($0) }
                            ),
                            in: 1...30,
                            step: 1
                        )
                        .accentColor(.blue)
                        
                        HStack {
                            Text("1 day")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("30 days")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Benefits")) {
                    Button(action: {
                        showBenefits = true
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.blue)
                            Text("Manage Benefits")
                            Spacer()
                            if let benefits = card.benefits, !benefits.isEmpty {
                                Text("\(benefits.filter { $0.isActive }.count)")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !cardName.isEmpty {
                            viewModel.updateCard(
                                card,
                                name: cardName,
                                lastFourDigits: lastFourDigits,
                                dueDate: dueDateDay,
                                reminderDaysAhead: reminderDaysAhead,
                                predefinedCardId: selectedPredefinedCard?.id
                            )
                            isPresented = false
                        }
                    }
                    .disabled(cardName.isEmpty)
                }
            }
            .sheet(isPresented: $showBenefits) {
                NavigationView {
                    BenefitsListView(card: card)
                }
            }
            .sheet(isPresented: $showCardPicker) {
                CardPickerView(
                    selectedCard: $selectedPredefinedCard,
                    isPresented: $showCardPicker,
                    onCardSelected: { predefinedCard in
                        selectedPredefinedCard = predefinedCard
                        // Don't change the card name - it should remain what the user set
                    }
                )
            }
        }
    }
    
    private func getOrdinalSuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

struct CardPickerView: View {
    @Binding var selectedCard: PredefinedCard?
    @Binding var isPresented: Bool
    var onCardSelected: (PredefinedCard?) -> Void
    
    @ObservedObject private var benefitsService = CardBenefitsService.shared
    @ObservedObject private var imageCache = ImageCacheService.shared
    @State private var searchText = ""
    
    private var filteredCards: [PredefinedCard] {
        if searchText.isEmpty {
            return benefitsService.predefinedCards
        } else {
            return benefitsService.searchPredefinedCards(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cards...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Cards List
                List {
                    // "Others" option at the top
                    Button(action: {
                        selectedCard = nil
                        onCardSelected(nil)
                        isPresented = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Others")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Custom card not in the list")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if selectedCard == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Predefined cards
                    ForEach(filteredCards) { card in
                        Button(action: {
                            selectedCard = card
                            onCardSelected(card)
                            isPresented = false
                        }) {
                            HStack(spacing: 12) {
                                // Card image
                                PredefinedCardImageView(
                                    cardId: card.id,
                                    imageUrl: card.imageUrl,
                                    imageCache: imageCache
                                )
                                .frame(width: 60, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.name)
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(card.issuer)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedCard?.id == card.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

