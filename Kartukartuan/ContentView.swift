import SwiftUI


struct Card: Codable, Identifiable {
    let id: String
    let name: String
    let manaCost: String?
    let typeLine: String
    let oracleText: String
    let colors: [String]
    let rarity: String
    let artist: String
    let foil: Bool
    let set: String
    let image_uris: ImageURIs?
    let prices: Prices?
    let legalities: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case manaCost = "mana_cost"
        case typeLine = "type_line"
        case oracleText = "oracle_text"
        case colors
        case rarity
        case set
        case image_uris
        case prices
        case legalities
        case artist
        case foil
    }
}

extension Card: Hashable {
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ImageURIs: Codable {
    let small: String?
    let normal: String?
    let large: String?
    let png: String?
    let art_crop: String?
    let border_crop: String?
}

struct Prices: Codable {
    let usd: String?
    let usdFoil: String?
    let usdEtched: String?
    let eur: String?
    let eurFoil: String?
    let tix: String?
}

class CardViewModel: ObservableObject {
    @Published var cards: [Card] = []
    private let pageSize = 45
    private var currentPage = 1
    @Published var isLoading = false
    
    init() {
        fetchCards()
    }
    
    func fetchCards() {
        if let url = Bundle.main.url(forResource: "WOT-Scryfall", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let response = try decoder.decode(CardResponse.self, from: data)
                let newCards = Array(response.data.prefix(pageSize * currentPage))
                cards.append(contentsOf: newCards)
                currentPage += 1
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }
    
}

struct CardResponse: Codable {
    let data: [Card]
}

struct ContentView: View {
    @ObservedObject var cardViewModel = CardViewModel()
    @State private var selectedCard: Card? = nil
    @State private var isBannerTapped: Bool = false
    @State private var searchText: String = ""
    @State private var isSortingSheetPresented: Bool = false
    @State private var sortOption: SortOption? = nil
    @State private var isAscending: Bool = true
    
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    HStack{
                        Spacer()
                        Button(action: {
                            isAscending.toggle()
                        }) {
                            Image(systemName: isAscending ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
                        )
                        
                        SortButtonView(isSortingSheetPresented: $isSortingSheetPresented, sortOption: $sortOption, isAscending: $isAscending)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(filteredAndSortedCards, id: \.id) { card in
                            CardView(card: card)
                                .onTapGesture {
                                    selectedCard = card
                                }
                                .sheet(item: $selectedCard) { selectedCard in
                                    NavigationView {
                                        CardDetailView(card: selectedCard, isBannerTapped: .constant(false))
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .id(searchText)
                }
            }
            .navigationTitle("Magic Cards")
        }
    }
    
    
    var filteredAndSortedCards: [Card] {
        var filteredCards = cardViewModel.cards
        
        if !searchText.isEmpty {
            filteredCards = filteredCards.filter { card in
                card.name.lowercased().contains(searchText.lowercased())
            }
        }
        if let sortOption = sortOption {
            switch sortOption {
            case .name:
                filteredCards.sort { $0.name < $1.name }
            case .priceUSD:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.usd ?? ""
                    let price2 = card2.prices?.usd ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .priceEUR:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.eur ?? ""
                    let price2 = card2.prices?.eur ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .priceTIX:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.tix ?? ""
                    let price2 = card2.prices?.tix ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .rarity:
                filteredCards.sort { $0.rarity < $1.rarity }
            case .color:
                filteredCards.sort { $0.colors.joined() < $1.colors.joined() }
            case .artist:
                filteredCards.sort { $0.artist < $1.artist }
            }
        }
        
        return filteredCards
    }
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: card.image_uris?.normal ?? "https://via.placeholder.com/150")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.red)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            
            HStack {
                Spacer()
            }
        }
        .frame(height: 175)
    }
}



struct CardDetailView: View {
    let card: Card
    @Binding var isBannerTapped: Bool
    @State private var isBannerImageTapped: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isBannerTapped {
                    AsyncImage(url: URL(string: card.image_uris?.large ?? "https://via.placeholder.com/150")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "xmark.octagon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.red)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .onTapGesture {
                        isBannerImageTapped = true
                    }
                    .overlay(
                        // Larger image overlay
                        AsyncImage(url: URL(string: card.image_uris?.large ?? "https://via.placeholder.com/150")) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Image(systemName: "xmark.octagon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                            .onTapGesture {
                                isBannerImageTapped = false
                            }
                            .padding()
                            .background(Color.black.opacity(0.9))
                            .ignoresSafeArea()
                            .opacity(isBannerImageTapped ? 1 : 0)
                    )
                } else {
                    AsyncImage(url: URL(string: card.image_uris?.art_crop ?? "https://via.placeholder.com/150")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "xmark.octagon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.red)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                }
                
                
                Text(card.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let manaCost = card.manaCost, !manaCost.isEmpty {
                    VStack{
                        Text("Mana Cost: \(manaCost)")
                        Spacer()
                        Divider()
                    }
                }
                
                Text("Oracle Text: \(card.oracleText)")
                
                if let prices = card.prices {
                    Text("Prices:")
                    if let usd = prices.usd {
                        Text("USD: \(usd)")
                    }
                    if let usdFoil = prices.usdFoil {
                        Text("USD Foil: \(usdFoil)")
                    }
                    if let usdEtched = prices.usdEtched{
                        Text("USD Etched: \(usdEtched)")
                    }
                    if let eur = prices.eur {
                        Text("EUR: \(eur)")
                    }
                    if let eurFoil = prices.eurFoil {
                        Text("EUR Foil: \(eurFoil)")
                    }
                    if let tix = prices.tix {
                        Text("TIX: \(tix)")
                    }
                }
                
                if let legalities = card.legalities, !legalities.isEmpty {
                    Section(header: Text("Legalities")) {
                        ForEach(Array(legalities.keys), id: \.self) { legalityType in
                            if let legalityValue = legalities[legalityType] {
                                HStack {
                                    Text(legalityType)
                                    Spacer()
                                    Text(legalityValue)
                                }
                                Divider()
                            }
                        }
                    }
                }
                
                Text("Rarity: \(card.rarity)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Artist: \(card.artist)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Foil: \(card.foil ? "Yes" : "No")")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Card Detail")
            .fullScreenCover(isPresented: $isBannerImageTapped) {
                AsyncImage(url: URL(string: card.image_uris?.large ?? "https://via.placeholder.com/150")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "xmark.octagon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    isBannerImageTapped = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button(action: {
                searchText = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .padding(4)
            }
            .opacity(searchText.isEmpty ? 0 : 1)
            .animation(.default)
        }
        .padding(8)
    }
}

extension RandomAccessCollection where Element: Identifiable {
    func isLastItem(_ item: Element) -> Bool {
        guard let index = self.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        return index == self.index(before: endIndex)
    }
}

struct BottomNavigationBar: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Cards", systemImage: "square.grid.2x2.fill")
                }
            
            SearchAndSortView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}

struct SearchAndSortView: View {
    @ObservedObject var cardViewModel = CardViewModel()
    
    @State private var searchText: String = ""
    @State private var isSortingSheetPresented: Bool = false
    @State private var sortOption: SortOption?
    @State private var isAscending: Bool = true
    @State private var selectedCard: Card? = nil
    
    var body: some View {
        VStack {
            HStack {
                SearchBar(searchText: $searchText)
                    .padding(8)
                Spacer()
            }
            .background(Color(.systemBackground))
            .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            
            if searchText.isEmpty {
                Text("Start typing to search for cards.")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(filteredAndSortedCards, id: \.id) { card in
                            CardView(card: card)
                                .onTapGesture {
                                    selectedCard = card
                                }
                                .sheet(item: $selectedCard) { selectedCard in
                                    NavigationView {
                                        CardDetailView(card: selectedCard, isBannerTapped: .constant(false))
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .id(searchText)
                }
            }
        }
        .navigationTitle("Search & Sort")
    }
    
    var filteredAndSortedCards: [Card] {
        guard !searchText.isEmpty else {
            return [] // Return an empty array if there is no search query
        }
        
        var filteredCards = cardViewModel.cards
        
        // Apply search
        filteredCards = filteredCards.filter { card in
            card.name.lowercased().contains(searchText.lowercased())
        }
        
        if let sortOption = sortOption {
            switch sortOption {
            case .name:
                filteredCards.sort { $0.name < $1.name }
            case .priceUSD:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.usd ?? ""
                    let price2 = card2.prices?.usd ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .priceEUR:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.eur ?? ""
                    let price2 = card2.prices?.eur ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .priceTIX:
                filteredCards.sort { card1, card2 in
                    let price1 = card1.prices?.tix ?? ""
                    let price2 = card2.prices?.tix ?? ""
                    return isAscending ? (price1 < price2) : (price1 > price2)
                }
            case .rarity:
                filteredCards.sort { $0.rarity < $1.rarity }
            case .color:
                filteredCards.sort { $0.colors.joined() < $1.colors.joined() }
            case .artist:
                filteredCards.sort { $0.artist < $1.artist }
            }
        }
        
        return filteredCards
    }
}




struct SortButtonView: View {
    @Binding var isSortingSheetPresented: Bool
    @Binding var sortOption: SortOption?
    @Binding var isAscending: Bool
    
    var body: some View {
        Button(action: {
            isSortingSheetPresented.toggle()
        }) {
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .rotationEffect(Angle(degrees: isAscending ? 0 : 180))
                    .foregroundColor(.blue)
                Text("Sort")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            )
        }
        .actionSheet(isPresented: $isSortingSheetPresented) {
            ActionSheet(
                title: Text("Sort By"),
                buttons: [
                    // Add new sorting categories here
                    ActionSheet.Button.default(Text("Name")) {
                        sortOption = .name
                    },
                    ActionSheet.Button.default(Text("Price (USD)")) {
                        sortOption = .priceUSD
                    },
                    ActionSheet.Button.default(Text("Price (EUR)")) {
                        sortOption = .priceEUR
                    },
                    ActionSheet.Button.default(Text("Price (TIX)")) {
                        sortOption = .priceTIX
                    },
                    ActionSheet.Button.default(Text("Rarity")) {
                        sortOption = .rarity
                    },
                    ActionSheet.Button.default(Text("Color")) {
                        sortOption = .color
                    },
                    ActionSheet.Button.default(Text("Artist")) {
                        sortOption = .artist
                    },
                    ActionSheet.Button.cancel()
                ]
            )
        }
    }
}


@main
struct YourAppNameApp: App {
    var body: some Scene {
        WindowGroup {
            BottomNavigationBar()
        }
    }
}
