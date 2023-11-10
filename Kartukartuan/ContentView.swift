import SwiftUI
import Foundation

struct Card: Codable, Identifiable {
    let id: String
    let name: String
    let manaCost: String
    let typeLine: String
    let oracleText: String
    let colors: [String]
    let rarity: String
    let set: String
    let image_uris: ImageURIs?
    
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

class CardViewModel: ObservableObject {
    @Published var cards: [Card] = []
    
    init() {
        if let url = Bundle.main.url(forResource: "WOT-Scryfall", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let response = try decoder.decode(CardResponse.self, from: data)
                self.cards = Array(response.data.prefix(6))
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
    
    var body: some View {
        NavigationView {
            List(cardViewModel.cards) { card in
                VStack(alignment: .leading) {
                    AsyncImage(url: card.image_uris?.normal)
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))                    
                    Text("Image: \(card.image_uris?.normal ?? "NA")")
                        .font(.title)
                    Text("Name: \(card.name)")
                        .font(.headline)
                    Text("Mana Cost: \(card.manaCost)")
                        .font(.subheadline)
                    Text("Type: \(card.typeLine)")
                        .font(.body)
                    Text("Oracle Text: \(card.oracleText)")
                        .font(.body)
                    Text("Colors: \(card.colors.joined(separator: ", "))")
                        .font(.body)
                    Text("Rarity: \(card.rarity)")
                        .font(.body)
                    Text("Set: \(card.set)")
                        .font(.body)
                }
            }
            .navigationTitle("Magic Cards")
        }
    }
}

struct MagicCardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
